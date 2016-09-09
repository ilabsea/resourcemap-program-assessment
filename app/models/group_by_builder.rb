class GroupByBuilder
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

      if(facet_filter_values.empty?)
        facet_tag =  value_field # // KampongCham_2015
        exp["#{facet_tag}"] = facet_term_stats_by_field(value_field)
      else
        facet_filter_values.each do |facet_filter_value|
          facet_tag = facet_filter_value.values.join("_") + "_#{value_field}" # // KampongCham_2015_aggrefieldx
          exp["#{facet_tag}"] = facet_term_stats_by_field(value_field, facet_filter_value)
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
      exp["#{facet_tag}"] = facet_statistical_by_field(stat_field)
    end
    exp
  end

  # {"province" => ['Kpc', 'PP']}
  def distinct_value(field_id)

    query = query_builder
    query['facets'] = {
      "#{field_id}" => {
        "terms" => {
          "field" => field_id
        }
      }
    }
    index_name = Collection.index_name(@report_query.collection_id)
    response = Tire.search(index_name, query).results


    terms = response.facets[field_id.to_s]["terms"]
    result = { "#{field_id}" => terms.map{|item| item['term']} }
    result
  end


  def facet_statistical_by_field agg_field_id
    {
      "statistical" => {
           "field" => "#{agg_field_id}"
       }
    }
  end

  # facet_filter_value = {province: 'kpc', year: 2015}
  def facet_term_stats_by_field value_field, facet_filter_value = {}
    #take last field as built in field
    key_field = @report_query.group_by_fields[-1]

    result = {
      "terms_stats" => {
        "key_field" => "#{key_field}",
        "value_field" => "#{value_field}"
      },
    }

    if(!facet_filter_value.empty?)
      terms = []
      facet_filter_value.each do |field_id, field_value|
        term = { "term" => {"#{field_id}" => field_value }}
        terms <<  term
      end
      result["facet_filter"] = {
        "bool" => {
          "must" => terms
        }
      }
    end
    result
  end

  # fields is a list of group by  with distinct value = [ { province: ['Kpc', 'Pp' ] }, { year: [ 2016, 2017] } ]
  def combine_tags(distinct_field_values)
    result = []
    build_combine_tags(distinct_field_values, result)
  end

  def build_combine_tags(fields, result)

    pop_field = fields.shift
    return result if pop_field.nil?

    field_key = pop_field.keys.first
    field_values = pop_field.values.flatten


    # [ { province: ['KampongCham', 'Phnom Penh' ] },
    #  { year: [ 2016, 2017] } ]
    # {province: 'kpc'}, {province: 'php'}
    # {province: 'kpc', year: 2016}, {province: 'php', year: 2016}
    # {province: 'kpc', year: 2016}, {province: 'php', year: 2016}

    empty_result = result.empty?
    temps = []

    field_values.each_with_index do |value, index|
      if(empty_result)
         temps << { "#{field_key}" => value}
      else
        result.each do |result_item|
          temp = result_item.clone
          temp["#{field_key}"] = value
          temps << temp
        end
      end
    end

    result = temps
    build_combine_tags(fields, result)
  end



end
