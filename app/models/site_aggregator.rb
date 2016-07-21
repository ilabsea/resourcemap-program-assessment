class SiteAggregator
  attr_accessor :site
  def initialize(site_object)
    @site = site_object
  end

  #TODO consider moving to counter_cache
  def save
    return false unless @site.valid?
    new_site = @site.new_record?
    @site.save!
    if(new_site)
      site_owner = site.user
      site_owner.site_count += 1
      site_owner.update_successful_outcome_status
      site_owner.save!(:validate => false)
    end
    #TODO consider enqueueing to let ElasticSearch enough time to index
    self.process
    true
  end

  def process
    return if site_criteria_properties.empty?

    search_result = search_ref_sites
    if !search_result.empty?
      if(@site.collection.is_aggregator)
        site_in_aggregator_collections = [@site]
        site_in_collection_ids = search_result.map{|result| result['_source']['id']}
      else
        aggregator_site_ids = search_result.map{ |item| item['_source']['id'] }
        site_in_aggregator_collections = Site.find aggregator_site_ids
        site_in_collection_ids = search_in_collection.map{|result| result['_source']['id']}
      end

      sites_in_collection = Site.find(site_in_collection_ids)
      SiteAggregatorUpdate.new(site_in_aggregator_collections, sites_in_collection).process
    end
  end


  #TODO handle duplicate records
  def search_ref_sites
    builder = {}
    # filter fields from other collections.
    conditions = []
    ref_properties_value.each do |id, value|
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
    query_result(query)
  end

  def query_result(query)
    s = Tire.search nil, query
    s.results
  end

  def search_in_collection
    builder = {}
    conditions = []
    field_criterias = @site.collection.fields.where(is_criteria: true)
    site_properties_criterias = @site.properties.slice(*field_criterias.map{|field| field.id.to_s})
    site_properties_criterias.each do |id, value|
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
    query_result(query)
  end


  # site = Site(properties: {80: '001', 81:'2016', 82: 'Sorya' })
  # ref_fields = [
  #                Obj(id: 100, name: "school", code: "school"),
  #                Obj(id: 101, name: "year", code: "year")]
  #

  # site_criteria_properties =  {"school": "0001", "year": 2015 },
  # expect results: { "100": "001", "101": 2015}

  def ref_properties_value
    result = {}
    ref_fields = mapping_fields_in_ref_collection
    ref_fields.each do |field|
      result["#{field.id}"] = site_criteria_properties[field.code]
    end
    result
  end

  # field_criterias = [Field(id:80, code: 'school'), Field(id:81, code: 'year')]
  # site = Site(properties: {80: '001', 81:'2016', 82: 'Sorya' })
  # expect {'school': '001', year: '2016'}

  def site_criteria_properties
    field_criterias = @site.collection.fields.where(is_criteria: true)
    results = {}
    field_criterias.each do |field|
      site_property_value = @site.properties[field.id.to_s]
      results[field.code] = site_property_value if site_property_value
    end
    results
  end

  def mapping_fields_in_ref_collection
    field_criterias = @site.collection.fields.where(is_criteria: true)
    Field.where(["collection_id != ? AND is_criteria = ?", @site.collection_id, true])
         .where(code: field_criterias.map(&:code))
  end
end
