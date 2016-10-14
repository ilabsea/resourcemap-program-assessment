namespace :report_query_collection do
  desc "Generate sample data for report_queries"

  task :sample_data => :environment do
    user = User.where(email: "thyda@instedd.org").first_or_initialize

    user.password = '123456'
    user.skip_confirmation!
    user.save(validate: false)


    collection = Collection.where(name: 'Report Query').first_or_create
    layer = collection.layers.where(name: 'General', ord: 1).first_or_initialize
    layer.user = user
    layer.save!

    membership = collection.memberships.where(user_id: user.id,
                                              admin: true,
                                              can_view_other: false,
                                              can_edit_other: false).first_or_create


    field_types = { text: Field::TextField,
                    numeric: Field::NumericField,
                    yes_no: Field::YesNoField,
                    select_one: Field::SelectOneField,
                    hierarchy: Field::HierarchyField,
                    location: Field::LocationField,

                   }
    hierarchy = [{"order"=>"1", "id"=>"1", "name"=>"PHD", "sub"=>[
                   {"order"=>"2", "id"=>"2", "name"=>"OD", "sub"=>[
                     {"order"=>"3", "id"=>"3", "name"=>"RH", "sub"=>[
                       {"order"=>"4", "id"=>"4", "name"=>"HC&HP"}
                    ]}
                  ]}
                ]}]


    options = [{"id"=>1, "code"=>"smp", "label"=>"SMP"},
               {"id"=>2, "code"=>"2", "label"=>"THR"},
               {"id"=>3, "code"=>"3", "label"=>"CASH"},
               {"id"=>4, "code"=>"smp_thr", "label"=>"SMP+THR"},
               {"id"=>5, "code"=>"5", "label"=>"SMP+CASH"}]

    locations = [{"code"=>"100", "name"=>"Phnom Penh", "latitude"=>"12.7237", "longitude"=>"104.893997"},
                 {"code"=>"200", "name"=>"Kandal", "latitude"=>"13.8067", "longitude"=>"104.958"},
                 {"code"=>"300", "name"=>"Takmao", "latitude"=>"10.4928", "longitude"=>"104.387001"},
                 {"code"=>"400", "name"=>"Siem Reap", "latitude"=>"11.4571", "longitude"=>"105.811996"},
                 {"code"=>"500", "name"=>"Romdol Chas", "latitude"=>"14.233", "longitude"=>"103.129997"},
                 {"code"=>"600", "name"=>"Romchong Leu", "latitude"=>"12.0016", "longitude"=>"105.444"}]

    [ { name: :province, type: :hierarchy, config: {"hierarchy" => hierarchy}},
      { name: :district, type: :hierarchy, config: {"hierarchy" => hierarchy}},
      { name: :victim, type: :text },
      { name: :income, type: :numeric, config: {"allow_decimal" => true} },
      { name: :program, type: :select_one, config: {"options" => options} },
      { name: :widow, type: :yes_no },
      { name: :house_hold, type: :numeric },
      { name: :women_effected, type: :numeric },
      { name: :near_by_hc, type: :location, config: {"locations" => locations}},
      { name: :year, type: :numeric }].each_with_index do |field_attrs, index|

      field_type = field_types[field_attrs[:type]]

      field = field_type.where(name: field_attrs[:name],
                               code: field_attrs[:name],
                               collection_id: collection.id,
                               layer_id: layer.id,
                               ord: index + 1 ).first_or_initialize
      field.config = field_attrs[:config]
      field.save

    end

    victims = ["Sok","Sao","Chan","Dara","Tevi","Vitou","Sum","Lao","Pou","Nun"]
    (1..100).each do |i|
      properties = {}

      layer.fields.each do |field|
        if field.kind == "text"
          properties[field.id.to_s] = victims[rand(10)]
        elsif field.kind == "numeric"
          properties[field.id.to_s] = (field.name == "year" ? 2010 + rand( 5) : rand(100))
        elsif field.kind == "yes_no"
          properties[field.id.to_s] = [true, false][rand(1)]
        elsif field.kind == "select_one"
          properties[field.id.to_s] = "#{rand(4) + 1}"
        elsif field.kind == "location"
          properties[field.id.to_s] = "#{(rand(5)+1) * 100}"
        elsif field.kind == "hierarchy"
          properties[field.id.to_s] = "#{rand(3) + 1}"
        end
      end

      site = collection.sites.where(name: "#{i+1}-site").first_or_initialize
      site.lat = 11.56438 + 50/(rand(50) + 50)
      site.lng = 104.92787 + 30/(rand(30) + 70)
      site.properties = properties
      site.user = user
      site.save!
      print("\r creating #{i} site") 

    end
  end
end
