class ReportQueryGroupByBuilder
  include ReportQueryBuilder
  attr_accessor :field_with_distinct_values, :term_stat_field

  def initialize(report_query)
    @report_query = report_query
  end

  # aggregate_fields: [{"id"=>"1", "field_id"=>"1019", "aggregator"=>"sum"}, {"id"=>"2", "field_id"=>"1020", "aggregator"=>"sum"}]
  def facet
    @report_query.group_by_fields.empty? ? facet_statisticals : facet_term_stats
  end

  def facet_term_stats
    exp = {}

    # leave last field as built in aggr, the rest for combination condition
    fields_combination_conditions = @report_query.group_by_fields[0..-2]

    # store possible unique value for condition combination
    distinct_field_values = [] #

    fields_combination_conditions.each do |field_id|
      distinct_field_values << distinct_value(field_id)
    end

    facet_filter_values = combine_tags(distinct_field_values)

    @report_query.aggregate_fields.each do |agg_field|
      value_field = agg_field["field_id"]

      if facet_filter_values.empty?
        facet_tag =  value_field # // KampongCham_2015
        exp[facet_tag] = facet_term_stats_by_field(value_field)
      else
        facet_filter_values.each do |facet_filter_value|
          facet_tag = facet_filter_value.values.join(ReportQuerySearchResult::DELIMITER) + "#{ReportQuerySearchResult::DELIMITER}#{value_field}" # // KampongCham_2015_aggrefieldx
          exp[facet_tag] = facet_term_stats_by_field(value_field, facet_filter_value)
        end
      end
    end

    exp
  end

  def facet_statisticals
    exp = {}
    @report_query.aggregate_fields.each do |agg_field|
      stat_field = agg_field["field_id"]
      facet_tag =  stat_field # // "province"
      exp[facet_tag] = facet_statistical_by_field(stat_field)
    end
    exp
  end


  def distinct_value_query(field_id)
    query = query_builder

    query['aggs'] = {
      field_id => {
        'terms' => {
          'field' => "properties.#{field_id}",
          'size' => Settings.max_aggregate_result_size.to_i
        }
      }
    }

    query
  end

  # {"province" => ['Kpc', 'PP']}
  def distinct_value(field_id)
    result = { }
    query = distinct_value_query(field_id)
    index_name = Collection.index_name(@report_query.collection_id)

    client = Elasticsearch::Client.new

    begin
      response = client.search index: index_name, body: query
      bucket_values = response['aggregations'][field_id]['buckets']
      result[field_id] = bucket_values.map { |value| value['key'] }
    rescue Exception => e
      Rails.logger.error e
    end

    result
  end


  def facet_statistical_by_field agg_field_id
    { 'stats' => { 'field' => "properties.#{agg_field_id}" } }
  end

  # facet_filter_value = { "province" => 'kpc', "year" => 2015}
  def facet_term_stats_by_field value_field, facet_filter_value = {}
    # take last field as built in field
    key_field = @report_query.group_by_fields[-1]

    aggregation_stats_query = fields_aggs(key_field, value_field)

    filtered_aggregation_query = filtered_aggs facet_filter_value

    unless filtered_aggregation_query.empty?
      aggregation_stats_query = filtered_aggregation_query['filtered_aggregation'].merge({ 'aggs' => aggregation_stats_query })
    end

    aggregation_stats_query
  end

  # fields is a list of group by  with distinct value = [ { "province" => ['Kpc', 'Pp' ] }, { "year" => [ 2016, 2017] } ]
  def combine_tags(distinct_field_values)
    build_combine_tags(distinct_field_values)
  end

  ##
  # params:
  #   fields: [{"province": ["kpc", "php"]}, {"year": [2016,2017]}]
  #   result: []
  # return: [{"province" => 'kpc', "year" => 2016}, {"province" => 'php', "year" => 2016},
  #   {"province" => 'kpc', "year" => 2017}, {"province" => 'php', "year" => 2017}]
  ##
  def build_combine_tags(fields, result = [])
    pop_field = fields.shift
    return result if pop_field.nil?

    field_key = pop_field.keys.first
    field_values = pop_field.values.flatten

    result = result.empty? ? combine_tag_without_result(field_key, field_values) : combine_tag_with_result(field_key, field_values, result)

    build_combine_tags(fields, result)
  end

  ##
  # params:
  #   field_key: "province"
  #   field_values: ["kpc", "php"]
  # return: [{province: "kpc"}, {province: "php"}]
  ##
  def combine_tag_without_result field_key, field_values
    elements = []

    field_values.each_with_index do |value, _index|
      element = {}
      element[field_key] = value
      elements << element
    end

    elements
  end

  ##
  # params:
  #   field_key: "year"
  #   field_values: [2016, 2017]
  # result: [{province: "kpc"}, {province: "php"}]
  # return: [{"province" => 'kpc', "year" => 2016}, {"province" => 'php', "year" => 2016},
  #   {"province" => 'kpc', "year" => 2017}, {"province" => 'php', "year" => 2017}]
  ##
  def combine_tag_with_result field_key, field_values, result = []
    elements = []

    field_values.each_with_index do |value, _index|
      result.each do |result_item|
        element = result_item.clone
        element[field_key] = value
        elements << element
      end
    end

    elements
  end

  def fields_aggs key_field, value_field
    @report_query.group_by_fields.count == 1 ? single_field_aggs(key_field, value_field) : multi_field_aggs(key_field, value_field)
  end

  def single_field_aggs key_field, value_field
    {
      'terms' => { 'field' => "properties.#{key_field}" },
      'aggs' => {
        'term' => { 'stats' => { 'field' => "properties.#{value_field}" } }
      }
    }
  end

  def multi_field_aggs key_field, value_field
    {
      "#{key_field}" => {
        'terms' => { 'field' => "properties.#{key_field}" },
        'aggs' => {
          'term' => { 'stats' => { 'field' => "properties.#{value_field}" } }
        }
      }
    }
  end

  def filtered_aggs aggs_filter_value = {}
    query = {}

    unless aggs_filter_value.empty?
      terms = []
      aggs_filter_value.each do |field_id, field_value|
        terms << { "term" => { "properties.#{field_id}" => field_value }}
      end

      query['filtered_aggregation'] = {
        'filter' => {
          'bool' => {
            'must' => terms
          }
        }
      }
    end

    query
  end

end
