require 'net/http'

namespace :site do
  desc "add the start entry and end entry date to sites"
  task :migrate => :environment do
    Site.add_start_and_end_entry_date
  end

  desc "add created_user_id to sites"
  task :add_created_user_id => :environment do
  	Site.add_created_user_id
  end

  desc "simulate site"
  task :simulate, [:collection_name, :num_of_sites] => [:environment] do |t, args|
    user = User.where(email: 'thyda@instedd.org').first
    collection = Collection.new(name: args[:collection_name])
    user.create_collection(collection)
    create_fields(collection)
    create_sites(collection, args[:num_of_sites].to_i)
  end


  desc 'reset_counter'
  task :reset_counter => :environment do
    Collection.find_each { |collection| Collection.reset_counters(collection.id, :sites) }
  end

  desc 'remove invalid control character'
  task :remove_invalid_char => :environment do
    Site.find_each { |site|
      site.name = site.name.gsub(/[^[:print:]]/) {|x| ''}
      site.save
    }
  end

  def create_fields(collection)
    layer = Layer.create(name: "Layer Test", collection_id: collection.id, ord: 1, user: collection.users.first)
    field_type = Field::BaseKinds.map{|item| item[:name]}
    #create 400 fields
    (1..400).each do |i|
      rand = Random.rand(11)
      FieldMock.create(collection.id, layer.id, field_type[rand], i)
    end

    #create 100 numeric fields
    (1..100).each do |i|
      FieldMock.create(collection.id, layer.id, 'numeric', i)
    end
  end

  def create_sites(collection, num_of_sites)
    #create 1000 sites
    (1..num_of_sites).each do |i|
      properties = {}

      collection.layers.each do |layer|
        layer.fields.each do |field|
          value = ''
          case field.kind
          when "text"
            value = "Text_#{Random.rand(100)}"
          when "numeric"
            value = Random.rand(100)
          when "yes_no"
            value = Random.rand(2)
          when "select_one", "select_many"
            value = Random.rand(field.config["options"].length)+1
          when "hierarchy"
            value = Random.rand(field.config["hierarchy"].length)+1
          when "date"
            value = DateTime.now.strftime "%Y-%m-%dT00:00:00Z"
          else
            value = "Text_#{Random.rand(100)}"
          end
          properties["#{field.id}"] = value
        end
      end
      Site.create(collection_id: collection.id, name: "Site_#{i}", lat: rand(-90.000000000...90.000000000), lng: rand(-180.000000000...180.000000000),
                properties: properties, user_id: collection.users.first.id)
    end
  end




end
