task :environment

namespace :migrate do
  desc "Migrate old skip logic data to new skip logic"
  task :skip_logic, [:ids] => :environment do |t, args|
    total_migrated = 0
    # list_collection_id = args[:ids].split(" ")
    total = Collection.all.size
    Collection.all.each_with_index do |collection, index|
      fields = collection.fields
      fields.each do |field|
        if field.support_skip_logic?
          percentage  = 100 * (index+1) / total
          print "\rMigrating skip logic "
          print "#{field.name}"
          field.migrate_skip_logic()
          total_migrated = total_migrated + 1
          print "\rMigrating skip logic logs for field #{index+1}/#{total}: %#{percentage}"
        end
      end
      collection.layers.each do |l|
        fs = l.fields
        fs.each do |field|
          p field.config
          field.config = field.config || {}
          field.config["field_logics"] = field.config["field_logics"] || []
          field.config["field_logics_tmp"] = field.config["field_logics_tmp"] || []
          field.config["field_logics"] = field.config["field_logics_tmp"]
          field.config.delete("field_logics_tmp")
          field.save!
        end
      end
    end
    print "\nTotal #{total_migrated} field(s) migrated in #{total} of collections\n"
  end  
end
