class ReportQueryResult
  DELIMITER = '_'

  def initialize(report_query, facet_result)
    @report_query = report_query
    @facet_result = facet_result
  end

  def agg_function_types
    return @field_aggregator_mapper unless @field_aggregator_mapper.nil?
    aggregator_mapping = {
      "count" => "count",
      "sum" => "total",
      "min" => "min",
      "max" => "max",
      "average" => "mean"
    }
    @field_aggregator_mapper = {}
    @report_query.aggregate_fields.each do |agg_field|
      @field_aggregator_mapper["#{agg_field['field_id']}"] = aggregator_mapping[agg_field['aggregator']]
    end
    @field_aggregator_mapper
  end

  # "3_district 5_2012" => {house_hold_key: 10, women_key: 20}
  def normalize
    @report_query.group_by_fields.empty? ? normalize_statistical : normalize_term_stats
  end

  def normalize_term_stats
    results = {}
    @facet_result.each do |key, search_value|
      key_names = key.split(DELIMITER)

      key_result = key_names[0..-2]  # [3, district5]

      agg_key_name = key_names[-1]

      search_value["terms"].each do |term|
        builtin_aggre = term['term']
        record_key = (key_result + [builtin_aggre]).join(DELIMITER)  # [3, district5, 2012]

        results[record_key] = results[record_key] || {}

        agg_function_type = agg_function_types[agg_key_name]
        agg_key_value = term[agg_function_type] # type of aggr SUM, COUNT
        results[record_key][agg_key_name] = agg_key_value

      end
    end
    results
  end

  def normalize_statistical
    results = {"" => {}}
    @facet_result.each do |key, search_value|
      agg_function_type = agg_function_types[key]
      results[""][key] = search_value[agg_function_type]
    end
    results
  end

end
