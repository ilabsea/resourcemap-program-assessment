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

    field_types = { text: Field::TextField, numeric: Field::NumericField }

    [ { name: :province_id, type: :numeric },
      { name: :district_name, type: :text } ,
      { name: :house_hold, type: :numeric },
      {  name: :women_effected, type: :numeric },
      {  name: :village_name, type: :text },
      {  name: :year, type: :numeric } ].each_with_index do |field, index|

      field_type = field_types[field[:type]]

      field = field_type.where(name: field[:name],
                               code: field[:name],
                               collection_id: collection.id,
                               layer_id: layer.id,
                               ord: index + 1 ).first_or_create

    end

    (1..100).each do |i|
      properties = {}

      layer.fields.each do |field|
        value = field.kind == "text" ? "text-#{field.id}" : (i%5) + 1
        properties[field.id.to_s] = value
      end

      inc = i * Random.rand(10)/100
      site = collection.sites.where(name: "site-#{i+1}").first_or_initialize
      site.lat = 11.56438 + inc*5
      site.lng = 104.92787 + inc
      site.properties = properties
      site.user = user

      site.save!

    end
  end
end
