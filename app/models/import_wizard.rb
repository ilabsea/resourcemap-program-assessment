class ImportWizard
  TmpDir = "#{Rails.root}/tmp/import_wizard"

  class << self
    def enqueue_job(user, collection, columns_spec)
      # debugger
      mark_job_as_pending user, collection

      # Enqueue job with user_id, collection_id, serialized column_spec
      Resque.enqueue ImportTask, user.id, collection.id, columns_spec
    end

    def enqueue_member_job(user, collection, columns_spec)
      # debugger
      mark_job_member_as_pending user, collection

      # Enqueue job with user_id, collection_id, serialized column_spec
      Resque.enqueue ImportMemberTask, user.id, collection.id, columns_spec
    end

    def cancel_pending_jobs(user, collection)
      mark_job_as_canceled_by_user(user, collection)
      delete_file(user, collection)
    end

    def cancel_pending_member_jobs(user, collection)
      mark_job_as_canceled_member_by_user(user, collection)
      delete_member_file(user, collection)
    end

    def import(user, collection, original_filename, contents)
      # Store representation of import job in database to enable status tracking later
      ImportJob.uploaded original_filename, user, collection

      FileUtils.mkdir_p TmpDir

      raise "Invalid file format. Only CSV files are allowed." unless File.extname(original_filename) == '.csv'

      begin
        File.open(file_for(user, collection), "wb") { |file| file << contents }
        csv = read_csv_for(user, collection)
        raise CSV::MalformedCSVError, "all rows must have the same number of columns." unless csv.all?{|e| e.count == csv[0].count}
      rescue CSV::MalformedCSVError => ex
        raise "The file is not a valid CSV: #{ex.message}"
      end
    end

    def import_members(user, collection, original_filename, contents)
      # Store representation of import job in database to enable status tracking later
      ImportJob.uploaded_members original_filename, user, collection

      FileUtils.mkdir_p TmpDir

      raise "Invalid file format. Only CSV files are allowed." unless File.extname(original_filename) == '.csv'

      begin
        File.open(file_member_for(user, collection), "wb") { |file| file << contents }
        csv = read_csv_member_for(user, collection)
        raise CSV::MalformedCSVError, "all rows must have the same number of columns." unless csv.all?{|e| e.count == csv[0].count}
      rescue CSV::MalformedCSVError => ex
        raise "The file is not a valid CSV: #{ex.message}"
      end
    end

    def validate_sites_with_columns(user, collection, columns_spec)
      columns_spec.map!{|c| c.with_indifferent_access}
      csv = read_csv_for(user, collection)
      csv_columns = csv[1.. -1].transpose

      validated_data = {}
      validated_data[:sites] = get_sites(csv, user, collection, columns_spec, 1)
      validated_data[:sites_count] = csv.length - 1

      csv[0].map! { |r| r.strip if r }

      validated_data[:errors] = calculate_errors(user, collection, columns_spec, csv_columns, csv[0])
      # TODO: implement pagination
      validated_data
    end

    def validate_members_with_columns(user, collection, columns_spec)
      columns_spec.map!{|c| c.with_indifferent_access}
      csv = read_csv_member_for(user, collection)
      csv_columns = csv[1.. -1].transpose

      validated_data = {}
      validated_data[:members] = get_sites(csv, user, collection, columns_spec, 1)
      validated_data[:members_count] = csv.length - 1

      csv[0].map! { |r| r.strip if r }

      validated_data[:errors] = calculate_member_errors(user, collection, columns_spec, csv_columns, csv[0])
      # TODO: implement pagination
      validated_data
    end

    def calculate_member_errors(user, collection, columns_spec, csv_columns, header)
      #Add index to each column spec
      columns_spec.each_with_index do |column_spec, column_index|
        column_spec[:index] = column_index
      end

      sites_errors = {}

      # Columns validation

      proc_select_new_fields = Proc.new{columns_spec.select{|spec| spec[:use_as].to_s == 'new_field'}}
      sites_errors[:duplicated_email] = calculate_duplicated_email(csv_columns)
      sites_errors[:existed_email] = calculate_existed_email(csv_columns, collection)
      sites_errors[:missing_email] = calculate_missing_email(csv_columns)

      sites_errors
    end

    def calculate_duplicated_email(csv)
      csv[0].detect{ |e| csv[0].count(e) > 1 } || []
    end

    def calculate_existed_email(csv, collection)
      errors = []
      csv[0].each do |email|
        user = User.where("email=?",email).first
        if user and collection.memberships.pluck(:user_id).include? user.id
          errors.push csv[0].index(email)
        end
      end
      return errors
    end

    def calculate_missing_email(csv)
      errors = []
      csv[0].each do |email|
        if User.where("email=?",email).size == 0
          errors.push csv[0].index(email)
        end
      end
      return errors
    end

    def calculate_errors(user, collection, columns_spec, csv_columns, header)
      #Add index to each column spec
      columns_spec.each_with_index do |column_spec, column_index|
        column_spec[:index] = column_index
      end

      sites_errors = {}

      # Columns validation

      proc_select_new_fields = Proc.new{columns_spec.select{|spec| spec[:use_as].to_s == 'new_field'}}
      sites_errors[:duplicated_code] = calculate_duplicated(proc_select_new_fields, 'code')
      sites_errors[:duplicated_label] = calculate_duplicated(proc_select_new_fields, 'label')
      sites_errors[:missing_label] = calculate_missing(proc_select_new_fields, 'label')
      sites_errors[:missing_code] = calculate_missing(proc_select_new_fields, 'code')

      sites_errors[:reserved_code] = calculate_reserved_code(proc_select_new_fields)

      collection_fields = collection.fields.all(:include => :layer)
      collection_fields.each(&:cache_for_read)

      sites_errors[:existing_code] = calculate_existing(columns_spec, collection_fields, 'code')
      sites_errors[:existing_label] = calculate_existing(columns_spec, collection_fields, 'label')

      # Calculate duplicated usage for default fields (lat, lng, id, name)
      proc_default_usages = Proc.new{columns_spec.reject{|spec| spec[:use_as].to_s == 'new_field' || spec[:use_as].to_s == 'existing_field' || spec[:use_as].to_s == 'ignore'}}
      sites_errors[:duplicated_usage] = calculate_duplicated(proc_default_usages, :use_as)
      # Add duplicated-usage-error for existing_fields
      proc_existing_fields = Proc.new{columns_spec.select{|spec| spec[:use_as].to_s == 'existing_field'}}
      sites_errors[:duplicated_usage].update(calculate_duplicated(proc_existing_fields, :field_id))

      # Name is mandatory
      sites_errors[:missing_name] = {:use_as => 'name'} if !(columns_spec.any?{|spec| spec[:use_as].to_s == 'name'})

      columns_used_as_id = columns_spec.select{|spec| spec[:use_as].to_s == 'id'}
      # Only one column will be marked to be used as id
      csv_column_used_as_id = csv_columns[columns_used_as_id.first[:index]] if columns_used_as_id.length > 0
      sites_errors[:non_existent_site_id] = calculate_non_existent_site_id(collection.sites.map{|s| s.id.to_s}, csv_column_used_as_id, columns_used_as_id.first[:index]) if columns_used_as_id.length > 0

      sites_errors[:data_errors] = []
      sites_errors[:hierarchy_field_found] = []

      # Rows validation

      csv_columns.each_with_index do |csv_column, csv_column_number|
        column_spec = columns_spec[csv_column_number]

        if column_spec[:use_as].to_s == 'new_field' && column_spec[:kind].to_s == 'hierarchy'
          sites_errors[:hierarchy_field_found] = add_new_hierarchy_error(csv_column_number, sites_errors[:hierarchy_field_found])
        elsif column_spec[:use_as].to_s == 'new_field' || column_spec[:use_as].to_s == 'existing_field'
          errors_for_column = validate_column(user, collection, column_spec, collection_fields, csv_column, csv_column_number)
          sites_errors[:data_errors].concat(errors_for_column)
        end
      end

      sites_errors
    end

    def add_new_hierarchy_error(csv_column_number, hierarchy_errors)
      if hierarchy_errors.length >0 && hierarchy_errors[0][:new_hierarchy_columns].length >0
        hierarchy_errors[0][:new_hierarchy_columns] << csv_column_number
      else
        hierarchy_errors = [{:new_hierarchy_columns => [csv_column_number]}]
      end
      hierarchy_errors
    end

    def get_sites(csv, user, collection, columns_spec, page)
      csv_columns = csv[1 .. 10]
      processed_csv_columns = []
      csv_columns.each do |csv_column|
        processed_csv_columns << csv_column.map{|csv_field_value| {value: csv_field_value} }
      end
      processed_csv_columns
    end

    def get_columns_members_spec(user, collection)
      rows = []
      CSV.foreach(file_member_for user, collection) do |row|
        rows << row
      end
      [
        {
          "header" => "email","kind" => "text","code" => "email","label" => "Email","use_as" => "new_field"
        },
        {
          "header" => "None","kind" => "yesno","code" => "none","label" => "None","use_as" => "new_field"
        },
        {
          "header" => "Read","kind" => "yesno","code" => "read","label" => "Read","use_as" => "new_field"
        },
        {
          "header" => "Update","kind" => "yesno","code" => "update","label" => "Update","use_as" => "new_field"
        },
        {
          "header" => "Admin","kind" => "yesno","code" => "admin","label" => "Admin","use_as" => "new_field"
        },
        {
          "header" => "View data submitted by other user","kind" => "yesno","code" => "viewdatasubmittedbyotheruser", "label" => "View Data Submitted By Other User","use_as" => "new_field"
        },
        {
          "header" => "Edit data submitted by other user","kind" => "yesno","code" => "editdatasubmittedbyotheruser", "label" => "Edit Data Submitted By Other
 User","use_as" => "new_field"
        }
      ]
    end

    def guess_columns_spec(user, collection)
      rows = []
      CSV.foreach(file_for user, collection) do |row|
        rows << row
      end
      to_columns collection, rows, user.admins?(collection)
    end

    def execute(user, collection, columns_spec)
      #Execute may be called with actual user and collection entities, or their ids.
      if !(user.is_a?(User) && collection.is_a?(Collection))
        #If the method's been called with ids instead of entities
        user = User.find(user)
        collection = Collection.find(collection)
      end

      import_job = ImportJob.last_for user, collection

      # Execution should continue only if the job is in status pending (user may canceled it)
      if import_job.status == 'pending'
        mark_job_as_in_progress(user, collection)
        execute_with_entities(user, collection, columns_spec)
      end
    end

    def execute_import_member(user, collection, columns_spec)
      #Execute may be called with actual user and collection entities, or their ids.
      if !(user.is_a?(User) && collection.is_a?(Collection))
        #If the method's been called with ids instead of entities
        user = User.find(user)
        collection = Collection.find(collection)
      end

      import_job = ImportJob.last_member_for user, collection

      # Execution should continue only if the job is in status pending (user may canceled it)
      if import_job.status == 'pending'
        mark_job_member_as_in_progress(user, collection)
        execute_import_member_with_entities(user, collection, columns_spec)
      end
    end

    def execute_with_entities(user, collection, columns_spec)
      spec_object = ImportWizard::ImportSpecs.new columns_spec, collection

      # Validate new fields
      spec_object.validate_new_columns_do_not_exist_in_collection

      # Read all the CSV to memory
      rows = read_csv_for(user, collection)

      # Put the index of the row in the columns spec
      rows[0].each_with_index do |header, i|
        next if header.blank?
        header = header.strip
        spec_object.annotate_index header, i
      end

      # Get the id spec
      id_spec = spec_object.id_column

      # Also get the name spec, as the name is mandatory
      name_spec = spec_object.name_column

      new_layer = spec_object.create_import_wizard_layer user

      begin
        sites = []

        # Now process all rows
        rows[1 .. -1].each do |row|
          # Check that the name is present
          next unless row[name_spec[:index]].present?

          site = nil
          site = collection.sites.find_by_id row[id_spec[:index]] if id_spec && row[id_spec[:index]].present?
          site ||= collection.sites.new properties: {}, collection_id: collection.id, from_import_wizard: true

          site.user = user
          sites << site

          # Optimization
          site.collection = collection

          # According to the spec
          spec_object.each_column do |column_spec|
            value = row[column_spec.index].try(:strip)
            column_spec.process row, site
          end
        end

        Collection.transaction do
          spec_object.new_fields.each_value do |field|
            field.save!
          end

          # Force computing bounds and such in memory, so a thousand callbacks are not called
          collection.compute_geometry_in_memory

          # Reload collection in order to invalidate cached collection.fields copy and to load the new ones
          collection.fields.reload

          # This will update the existing sites
          sites.each { |site| site.save! unless site.new_record? }
          # And this will create the new ones
          collection.save!

          mark_job_as_finished(user, collection)
        end
      rescue Exception => ex
        # Delete layer created by this import process if something unexpectedly fails
        new_layer.destroy if new_layer
        raise ex
      end

      delete_file(user, collection)
    end

    def execute_import_member_with_entities(user, collection, columns_spec)
      spec_object = ImportWizard::ImportSpecs.new columns_spec, collection

      # Read all the CSV to memory
      rows = read_csv_member_for(user, collection)

      # Put the index of the row in the columns spec
      rows[0].each_with_index do |header, i|
        next if header.blank?
        header = header.strip
        spec_object.annotate_index header, i
      end

      begin
        members = []
        layer_members = []
        # Now process all rows
        rows[1 .. -1].each do |row|
          member = nil
          can_read_other = to_boolean row[5]
          can_edit_other = to_boolean row[6] 
          admin = to_boolean row[4]
          none = to_boolean row[1]
          read = to_boolean row[2]
          write = to_boolean row[3]
          email = row[0].strip
          user_member = User.where("email=?",email)
          puts user_member.first.id
          member ||= collection.memberships.new admin: admin , can_view_other: can_read_other, can_edit_other: can_edit_other

          if user_member
            unless admin
              collection.layers.each do |layer|
                if read || write
                  lm = collection.layer_memberships.new layer_id: layer.id, read: read, write: write, user_id: user_member.first.id
                  layer_members << lm
                end
              end
            end
            member.user_id = user_member.first.id
            member.collection_id = collection.id
            members << member
          end
        end
        puts layer_members
        Collection.transaction do

          # This will update the existing sites
          members.each { |member| member.save! }
          layer_members.each { |lm| lm.save! }
          # And this will create the new ones

          mark_job_member_as_finished(user, collection)
        end
      rescue Exception => ex
        raise ex
      end

      delete_member_file(user, collection)
    end


    def delete_file(user, collection)
      File.delete(file_for(user, collection))
    end

    def delete_member_file(user, collection)
      File.delete(file_member_for(user, collection))
    end

    def mark_job_as_pending(user, collection)
      # Move the corresponding ImportJob to status pending, since it'll be enqueued
      (ImportJob.last_for user, collection).pending
    end

    def mark_job_member_as_pending(user, collection)
      # Move the corresponding ImportJob to status pending, since it'll be enqueued
      (ImportJob.last_member_for user, collection).pending
    end

    def mark_job_as_canceled_by_user(user, collection)
      (ImportJob.last_for user, collection).canceled_by_user
    end

    def mark_job_as_canceled_member_by_user(user, collection)
      (ImportJob.last_member_for user, collection).canceled_member_by_user
    end

    def mark_job_as_in_progress(user, collection)
      (ImportJob.last_for user, collection).in_progress
    end

    def mark_job_as_finished(user, collection)
      (ImportJob.last_for user, collection).finish
    end

    def mark_job_member_as_in_progress(user, collection)
      (ImportJob.last_member_for user, collection).in_progress
    end

    def mark_job_member_as_finished(user, collection)
      (ImportJob.last_member_for user, collection).finish
    end

    private

    def to_boolean value
      value.to_s == "1" or value.to_s.upcase == 'YES' or value.to_s.upcase == 'Y'
    end

    def calculate_non_existent_site_id(valid_site_ids, csv_column, resmap_id_column_index)
      invalid_ids = []
      csv_column.each_with_index do |csv_field_value, field_number|
        invalid_ids << field_number unless (csv_field_value.blank? || valid_site_ids.include?(csv_field_value.to_s))
      end
      [{rows: invalid_ids, column: resmap_id_column_index}] if invalid_ids.length >0
    end

    def validate_column(user, collection, column_spec, fields, csv_column, column_number)
      if column_spec[:use_as].to_sym == :existing_field
        field = fields.detect{|e| e.id.to_s == column_spec[:field_id].to_s}
      else
        field = Field.new kind: column_spec[:kind].to_s
      end

      validated_csv_column = []
      csv_column.each_with_index do |csv_field_value, field_number|
        begin
          validate_column_value(column_spec, csv_field_value, field, collection)
        rescue => ex
          description = error_description_for_type(field, column_spec, ex)
          validated_csv_column << {description: description, row: field_number}
        end
      end

      validated_columns_grouped = validated_csv_column.group_by{|e| e[:description]}
      validated_columns_grouped.map do |description, hash|
        {description: description, column: column_number, rows: hash.map { |e| e[:row] }, type: field.value_type_description, example: field.value_hint }
      end
    end

    def error_description_for_type(field, column_spec, ex)
      column_index = column_spec[:index]
      "Some of the values in column #{column_index + 1} #{field.error_description_for_invalid_values(ex)}."
    end

    def calculate_duplicated(selection_block, groping_field)
      spec_to_validate = selection_block.call()
      spec_by_field = spec_to_validate.group_by{ |s| s[groping_field]}
      duplicated_columns = {}
      spec_by_field.each do |column_spec|
        if column_spec[1].length > 1
          duplicated_columns[column_spec[0]] = column_spec[1].map{|spec| spec[:index] }
        end
      end
      duplicated_columns
    end

    def calculate_reserved_code(selection_block)
      spec_to_validate = selection_block.call()
      invalid_columns = {}
      spec_to_validate.each do |column_spec|
        if Field.reserved_codes().include?(column_spec[:code])
          if invalid_columns[column_spec[:code]]
            invalid_columns[column_spec[:code]] << column_spec[:index]
          else
            invalid_columns[column_spec[:code]] = [column_spec[:index]]
          end
        end
      end
      invalid_columns
    end

    def calculate_missing(selection_block, missing_value)
      spec_to_validate = selection_block.call()
      missing_value_columns = []
      spec_to_validate.each do |column_spec|
        if column_spec[missing_value].blank?
          if missing_value_columns.length >0
            missing_value_columns << column_spec[:index]
          else
            missing_value_columns = [column_spec[:index]]
          end
        end
      end
      {:columns => missing_value_columns} if missing_value_columns.length >0
    end

    def calculate_existing(columns_spec, collection_fields, grouping_field)
      spec_to_validate = columns_spec.select {|spec| spec[:use_as] == 'new_field'}
      existing_columns = {}
      spec_to_validate.each do |column_spec|
        #Refactor this
        if grouping_field == 'code'
          found = collection_fields.detect{|f| f.code == column_spec[grouping_field]}
        elsif grouping_field == 'label'
          found = collection_fields.detect{|f| f.name == column_spec[grouping_field]}
        end
        if found
          if existing_columns[column_spec[grouping_field]]
            existing_columns[column_spec[grouping_field]] << column_spec[:index]
          else
            existing_columns[column_spec[grouping_field]] = [column_spec[:index]]
          end
        end
      end
      existing_columns
    end

    def validate_column_value(column_spec, field_value, field, collection)
      if field.new_record?
        validate_format_value(column_spec, field_value, collection)
      else
        field.apply_format_and_validate(field_value, true, collection)
      end
    end

    def validate_format_value(column_spec, field_value, collection)
      # Bypass some field validations
      if column_spec[:kind] == 'hierarchy'
        raise "Hierarchy fields can only be created via web in the Layers page"
      elsif column_spec[:kind] == 'select_one' || column_spec[:kind] == 'select_many'
        # options will be created
        return field_value
      end

      column_header = column_spec[:code]? column_spec[:code] : column_spec[:label]

      sample_field = Field.new kind: column_spec[:kind], code: column_header

      # We need the collection to validate site_fields
      sample_field.collection = collection

      sample_field.apply_format_and_validate(field_value, true, collection)
    end

    def to_columns(collection, rows, admin)
      fields = collection.fields.index_by &:code
      columns_initial_guess = []
      rows[0].each do |header|
        column_spec = {}
        column_spec[:header] = header ? header.strip : ''
        column_spec[:kind] = :text
        column_spec[:code] = header ? header.downcase.gsub(/\s+/, '') : ''
        column_spec[:label] = header ? header.titleize : ''
        columns_initial_guess << column_spec
      end

      columns_initial_guess.each_with_index do |column, i|
        guess_column_usage(column, fields, rows, i, admin)
      end
    end

    def guess_column_usage(column, fields, rows, i, admin)
      if (field = fields[column[:header]])
        column[:use_as] = :existing_field
        column[:layer_id] = field.layer_id
        column[:field_id] = field.id
        column[:kind] = field.kind.to_sym
        return
      end

      if column[:header] =~ /^resmap-id$/i
        column[:use_as] = :id
        column[:kind] = :id
        return
      end

      if column[:header] =~ /^name$/i
        column[:use_as] = :name
        column[:kind] = :name
        return
      end

      if column[:header] =~ /^\s*lat/i
        column[:use_as] = :lat
        column[:kind] = :location
        return
      end

      if column[:header] =~ /^\s*(lon|lng)/i
        column[:use_as] = :lng
        column[:kind] = :location
        return
      end

      if column[:header] =~ /start entry date/i
        column[:use_as] = :start_entry_date
        column[:kind] = :date
        return
      end

      if column[:header] =~ /end entry date/i
        column[:use_as] = :end_entry_date
        column[:kind] = :date
        return
      end

      if column[:header] =~ /last updated/i
        column[:use_as] = :ignore
        column[:kind] = :ignore
        return
      end     

      if not admin
        column[:use_as] = :ignore
        return
      end

      found = false

      rows[1 .. -1].each do |row|
        next if row[i].blank?

        found = true

        if row[i].start_with?('0')
          column[:use_as] = :new_field
          column[:kind] = :text
          return
        end

        begin
          Float(row[i])
        rescue
          column[:use_as] = :new_field
          column[:kind] = :text
          return
        end
      end

      if found
        column[:use_as] = :new_field
        column[:kind] = :numeric
      else
        column[:use_as] = :ignore
      end
    end

    def read_csv_for(user, collection)
      csv = CSV.read(file_for(user, collection))

      # Remove empty rows at the end
      while (last = csv.last) && last.empty?
        csv.pop
      end

      csv
    end

    def read_csv_member_for(user, collection)
      csv = CSV.read(file_member_for(user, collection))

      # Remove empty rows at the end
      while (last = csv.last) && last.empty?
        csv.pop
      end

      csv
    end

    def file_for(user, collection)
      "#{TmpDir}/#{user.id}_#{collection.id}.csv"
    end

    def file_member_for(user, collection)
      "#{TmpDir}/#{user.id}_#{collection.id}_members.csv"
    end
  end
end
