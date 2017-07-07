class SiteAggregatorUpdate
  def initialize(site_in_aggregator_collections, sites_in_collection)
     @site_in_aggregator_collections = site_in_aggregator_collections
     @sites_in_collection = sites_in_collection
  end
  def process
    @site_in_aggregator_collections.each do |site_in_aggregator_collection|
      process_each(site_in_aggregator_collection)
    end
  end

  def process_each site_in_aggregator_collection
    field_aggregators.each do |field_aggregator|
      site_in_aggregator_collection.properties["#{field_aggregator.id}"] = field_aggragator_result(field_aggregator)
    end
    site_in_aggregator_collection.save
  end

  def field_aggregators
    @field_aggregators ||= @site_in_aggregator_collections.first.collection.fields.select{|field| field.is_custom_aggregator}
  end

  def field_aggragator_result field_aggregator
    values = []
    aggragator_type = field_aggregator.config['selected_aggregator_type']
    @sites_in_collection.each do |site_in_collection|
      values << field_agggregator_result_per_site(site_in_collection, field_aggregator)
    end
    calculate_aggregator(aggragator_type, values)
  end

  def field_agggregator_result_per_site site_in_collection, field_aggregator
    total = 0
    field_aggregator.config['aggregated_field_list'].each do |i, field_in_collection_attr|
      field_id_in_collection = field_in_collection_attr['id']

      if field_has_no_condition?(field_aggregator)
        total += site_in_collection['properties'][field_id_in_collection] || 0
      elsif site_in_collection_match_field_condition(site_in_collection, field_aggregator)
        total += site_in_collection['properties'][field_id_in_collection] || 0
      end
    end
    total
  end

  def site_in_collection_match_field_condition site_in_collection, field_aggregator
    condition_field_id    = field_aggregator.config['condition_field_id']
    condition_field_value = field_aggregator.config['condition_field_value']
    site_in_collection['properties']["#{condition_field_id}"].to_s == condition_field_value
  end

  def field_has_no_condition? field_aggregator
    field_aggregator.config['condition_field_id'].blank? || field_aggregator.config['condition_field_value'].blank?
  end

  def calculate_aggregator aggragator_type, values
    case aggragator_type
      when "SUM"
       values.sum
     when "MIN"
       values.min
     when "MAX"
       values.max
    else
      0
    end
  end
end
