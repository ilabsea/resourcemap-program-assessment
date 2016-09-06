class GroupByParser
  attr_accessor :field_with_distinct_values, :term_stat_field

  def initialize(field_with_distinct_values, agg_fields)
    @field_with_distinct_values = field_with_distinct_values
    @agg_fields = agg_fields
    @term_stat_field = @field_with_distinct_values.pop.keys.first
  end

# aggregate_fields: [{"id"=>"1", "field_id"=>"1019", "aggregator"=>"sum"}, {"id"=>"2", "field_id"=>"1020", "aggregator"=>"sum"}]
  def facet_filters
    exp = {}
    facet_filter_values = combine_tags(@field_with_distinct_values)
    @agg_fields.each do |agg_field|
      agg_field_id = agg_field["field_id"]
      if(facet_filter_values.empty?)
        facet_tag =  agg_field_id # // KampongCham_2015
        exp["#{facet_tag}"] = facet_per_aggregator(agg_field_id)
      else
        facet_filter_values.each do |facet_filter_value|
          facet_tag = facet_filter_value.values.join("_") + "_" + agg_field_id # // KampongCham_2015
          exp["#{facet_tag}"] = facet_per_aggregator(agg_field_id, facet_filter_value)
        end
      end
    end
    exp
  end

  # facet_filter_value = {province: 'kpc', year: 2015}
  def facet_per_aggregator agg_field_id, facet_filter_value = {}
    result = {
      "terms_stats" => {
        "key_field" => "#{@term_stat_field}",
        "value_field" => agg_field_id
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
  def combine_tags(fields)
    result = []
    build_combine_tags(fields, result)
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
