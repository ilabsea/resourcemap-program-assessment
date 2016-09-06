class ReportQuerySearch
  DEFAULT_SIZE = 100
  attr_accessor :result, :facet
  def initialize(report_query)
    @report_query = report_query
    @index_name = Collection.index_name(@report_query.collection_id)
  end

  def query
    result_query = query_builder
    if(!@report_query.aggregate_fields.empty?)
      result_query['facets'] = facet_builder
    end
    result_query['size'] = DEFAULT_SIZE
    response = Tire.search(@index_name, result_query).results
    @result = response.results.map { |item| item["_source"]["properties"].values.join(", ")}
    @facet = response.facets
  end

  def query_builder
    builder = {}
    match_all = { "match_all" => {} }
    if @report_query.condition.empty?
      builder["query"] = match_all
    else
      builder["query"] = {"filtered" =>{
                                        "query" => match_all,
                                        "filter" => parse_condition
                                      }
                          }
    end
    builder
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
    response = Tire.search(@index_name, query).results
    {
      "#{field_id}" => response.facets[field_id]["terms"].map{|item| item['term']}
    }
  end

  # ["field_id_1", "field_id_2"]
  def facet_builder
    group_by_fields = @report_query.group_by_fields.clone
    aggregate_fields = @report_query.aggregate_fields.clone

    distinct_field_values = []
    term_stat_field = group_by_fields.pop

    group_by_fields.each do |field_id|
      distinct_values = self.distinct_value(field_id)
      distinct_field_values << distinct_values
    end

    distinct_field_values << { "#{term_stat_field}" => nil}
    GroupByParser.new(distinct_field_values, aggregate_fields).facet_filters
  end

  # group_by_fields: ["1017", "1018"]
  # aggregate_fields: [{"id"=>"1", "field_id"=>"1019", "aggregator"=>"sum"},
                    # {"id"=>"2", "field_id"=>"1020", "aggregator"=>"sum"}]


#<ReportQuery id: 11, name: "Province  3  - Houeshold > 3  or Women Effected < 4...",
# condition_fields: [ {"id"=>"1", "field_id"=>"1017", "operator"=>"=", "value"=>"3"},
#                     {"id"=>"2", "field_id"=>"1019", "operator"=>">", "value"=>"3"},
#                     {"id"=>"3", "field_id"=>"1020", "operator"=>"<", "value"=>"4"}],
# condition: "1 and ( 2 or 3 )">

  def query_filter_range(condition_field)
    operator_types = {">" => "gt", "<" => "lt", ">=" => "gte", "<=" => "lte" }

    operator = condition_field["operator"]
    field_id = condition_field["field_id"]
    value = condition_field["value"]
    operator_type = operator_types[operator]
    {
      "range" => {
        "#{field_id}" => {
          "#{operator_type}" => "#{value}"
        }
      }
    }
  end

  def query_filter_term(condition_field)
    field_id = condition_field["field_id"]
    value = condition_field["value"]
    {
      "term" => {
        "#{field_id}" => "#{value}"
      }
    }
  end

  def query_filters
    results = {}
    @report_query.condition_fields.each do |condition_field|
      if(condition_field["operator"] == "=" )
        results[condition_field["id"]] = self.query_filter_term(condition_field)
      else
        results[condition_field["id"]] = self.query_filter_range(condition_field)
      end
    end
    results
  end

  def parse_condition
    filter_results = self.query_filters
    ConditionParser.new(@report_query.condition).parse do |current_token|
      filter_results[current_token]
    end
  end


end
