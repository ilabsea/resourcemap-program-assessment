class SiteAggregatorUpdate
  def initialize(site_in_ref_collection, sites_in_collection)
     @site_in_ref_collection = site_in_ref_collection
     @sites_in_collection = sites_in_collection
  end
  def start
    field_aggregators = @site_in_ref_collection.collection.fields.select{|field| field.is_custom_aggregator}

    field_aggregators.each do |field_aggregator|
      @site_in_ref_collection.properties["#{field_aggregator.id}"] = field_aggragator_result(field_aggregator)
    end
    p @site_in_ref_collection
    @site_in_ref_collection.save
  end

  def field_aggragator_result field_aggregator
    values = []
    aggragator_type = field_aggregator.config['selected_aggregator_type']
    @sites_in_collection.each do |site_in_collection|
      values << agggregate_result_per_site(site_in_collection, field_aggregator)
    end
    calculate_aggregator(aggragator_type, values)
  end

  def agggregate_result_per_site site_in_collection, field_aggregator
    total = 0
    field_aggregator.config['aggregated_field_list'].each do |i, field_in_collection_attr|
      field_id_in_collection = field_in_collection_attr['id']

      if field_has_no_condition?(field_aggregator)
        total += site_in_collection['properties'][field_id_in_collection] || 0
      else
        condition_field_id = field_aggregator.config['selected_collection_condition_field']
        if site_in_collection['properties']["#{condition_field_id}"].to_s == field_aggregator.config['condition_field_value']
          total += site_in_collection['properties'][field_id_in_collection] || 0
        end
      end
    end
    total
  end

  def field_has_no_condition? field_aggregator
    field_aggregator.config['selected_collection_condition_field'].empty? || field_aggregator.config['condition_field_value'].empty?
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
