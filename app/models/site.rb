# == Schema Information
#
# Table name: sites
#
#  id               :integer          not null, primary key
#  collection_id    :integer
#  name             :string(255)
#  lat              :decimal(10, 6)
#  lng              :decimal(10, 6)
#  parent_id        :integer
#  hierarchy        :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  properties       :text
#  location_mode    :string(10)       default("automatic")
#  id_with_prefix   :string(255)
#  uuid             :string(255)
#  device_id        :string(255)
#  external_id      :string(255)
#  start_entry_date :datetime         default(2015-08-14 02:57:03 UTC)
#  end_entry_date   :datetime         default(2015-08-14 02:57:03 UTC)
#  user_id          :integer
#

class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::CleanupConcern
  include Site::GeomConcern
  include Site::PrefixConcern
  include Site::TireConcern
  include HistoryConcern

  belongs_to :collection
  validates_presence_of :name

  #Site belong to user created
  belongs_to :user

  serialize :properties, Hash
  validate :valid_properties
  after_validation :standardize_properties
  before_validation :assign_default_values, :on => :create

  after_save :touch_collection_lifespan
  after_destroy :touch_collection_lifespan

  attr_accessor :from_import_wizard

  def history_concern_foreign_key
    self.class.name.foreign_key
  end

  def extended_properties
    @extended_properties ||= Hash.new
  end

  def update_properties(site, user, props)
    props.each do |p|
      field = Field.where(:collection_id => site.collection.id, :code => p.values[0]).first
      site.properties[field.id.to_s] = p.values[1]
    end
    site.save!
  end

  def human_properties
    fields = collection.fields.index_by(&:es_code)

    props = {}
    properties.each do |key, value|
      field = fields[key]
      if field
        props[field.name] = field.human_value value
      else
        props[key] = value
      end
    end
    props
  end

  def self.add_created_user_id
    Site.transaction do
      Site.find_each(batch_size: 100) do |site|
        activity = Activity.find_by_site_id_and_action(site.id, "created")
        site.user_id = activity.user_id
        site.save!(:validate => false)
        print "\."
      end
    end
    print 'Done!'
  end


  def self.add_start_and_end_entry_date
    Site.transaction do
      Site.find_each(batch_size: 100) do |site|
        site.start_entry_date = site.created_at
        site.end_entry_date = site.created_at
        site.save!(:validate => false)
        print "\."
      end
    end
    print 'Done!'
  end

  def self.get_id_and_name sites
    sites = Site.select("id, name").find(sites)
    sites_with_id_and_name = []
    sites.each do |site|
      site_with_id_and_name = {
        "id" => site.id,
        "name" => site.name
      }
      sites_with_id_and_name.push site_with_id_and_name
    end
    sites_with_id_and_name
  end

  def self.create_or_update_from_hash! hash
    site = Site.where(:id => hash["site_id"]).first_or_initialize
    site.prepare_attributes_from_hash!(hash)
    site.save ? site : nil
  end

  def prepare_attributes_from_hash!(hash)
    self.collection_id = hash["collection_id"]
    self.name = hash["name"]
    self.lat = hash["lat"]
    self.lng = hash["lng"]
    self.user = hash["current_user"]
    properties = {}
    hash["existing_fields"].each_value do |field|
      properties[field["field_id"].to_s] = field["value"]
    end
    self.properties = properties
  end

  def filter_site_by_id site_id
    builder = Site.find site_id
  end

  private

  def standardize_properties
    fields = collection.fields.index_by(&:es_code)

    standardized_properties = {}
    properties.each do |es_code, value|
      field = fields[es_code]
      if field
        standardized_properties[es_code] = field.standadrize(value)
      end
    end
    self.properties = standardized_properties
  end

  def assign_default_values
    fields = collection.fields.index_by(&:es_code)

    fields.each do |es_code, field|
      if properties[field.es_code].blank?
        value = field.default_value_for_create(collection)
        properties[field.es_code] = value if value
      end
    end
  end

  def valid_properties
    return unless valid_lat_lng
    fields = collection.fields.index_by(&:es_code)
    fields_mandatory = collection.fields.find_all_by_is_mandatory(true)
    properties.each do |es_code, value|
      field = fields[es_code]
      if field
        begin
          field.valid_value?(value, self)
        rescue => ex
          errors.add(:properties, {field.es_code => ex.message})
        end
      end
    end
  end

  def valid_lat_lng
    valid = false

    if lat
      if (lat >= -90) && (lat <= 90)
        valid = true
      else
        errors.add(:lat, "latitude must be in the range of -90 to 90")
        return false
      end
    end

    if lng
      if (lng >= -180) && (lng <= 180)
        valid = true
      else
        errors.add(:lng, "longitude must be in the range of -180 to 180")
        return false
      end
    end

    return valid
  end
end
