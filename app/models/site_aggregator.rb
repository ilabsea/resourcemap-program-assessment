class SiteAggregator
  def initialize(site)
    @site = site
  end

  def process
    return unless has_criteria_fields_in_ref_collection?

    ref_site_id = search_in_ref_collection.first['_source']['id']
    site_in_ref_collection = Site.find ref_site_id

    site_in_collection_ids = search_in_collection.map{|result| result['_source']['id']}
    sites_in_collection = Site.find(site_in_collection_ids)
    SiteAggregatorUpdate.new(site_in_ref_collection, sites_in_collection).start
  end

  #TODO handle duplicate records
  def search_in_ref_collection
    builder = {}
    # filter fields from other collections.
    conditions = []

    criteria_field_values_in_ref_collection_conditions.each do |id, value|
      conditions << { term: { "#{id}" => value } }
    end

    filter = {
      and: conditions
    }
    builder[:filter] = filter
    builder[:query]  = { match_all: {} }
    query = {
      query: {
        filtered: builder
      }
    }
    s = Tire.search nil, query
    tire_result = s.results
    tire_result.results
  end

  def search_in_collection
    builder = {}
    conditions = []

    criteria_field_values_in_collection.each do |id, value|
      conditions << { term: { "#{id}" => value } }
    end
    conditions << { term: { "collection_id" => @site.collection_id } }
    filter = {
      and: conditions
    }
    builder[:filter] = filter
    builder[:query]  = { match_all: {} }
    query = {
      query: {
        filtered: builder
      }
    }
    s = Tire.search nil, query
    tire_result = s.results
    tire_result.results
  end

  def criteria_fields
    @criteria_fields ||= @site.collection.fields.where(is_criteria: true)
  end

  def has_criteria_fields_in_ref_collection?
    !criteria_field_values_in_ref_collection.empty?
  end

  def criteria_field_values_in_collection
    results = {}
    criteria_fields.each do |field|
      site_property_value = @site.properties[field.id.to_s]
      results["#{field.id}"] = site_property_value if site_property_value
    end
    results
  end

  def criteria_field_values_in_ref_collection
    results = {}
    criteria_fields.each do |field|
      site_property_value = @site.properties[field.id.to_s]
      results[field.code] = site_property_value if site_property_value
    end
    results
  end

  # fields_in_ref_collection = [
  #                      Obj(id: 100, name: "school", code: "school"),
  #                      Obj(id: 101, name: "year", code: "year")]
  #

  # criteria_field_values_in_ref_collection =  {"school": "0001", "year": 2015 },
  # expect results: { "100": "001", "101": 2015}

  def criteria_field_values_in_ref_collection_conditions
    results = {}
    fields_in_ref_collection.each do |field|
      results["#{field.id}"] = criteria_field_values_in_ref_collection[field.code]
    end
    results
  end

  def fields_in_ref_collection
    criteria_fields_codes = criteria_fields.map(&:code)
    Field.where(["collection_id != ?", @site.collection_id] )
         .where(code: criteria_fields_codes)
  end
end
