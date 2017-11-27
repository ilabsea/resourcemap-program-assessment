module ReportQueryBuilder

  def query_builder
    builder = {}

    if @report_query.condition.empty?
      builder["query"] = { "match_all" => {} }
    else
      builder["query"] = {
        "filtered" => {
          "query" => { "match_all" => {} },
          "filter" => parse_condition
        }
      }
    end

    builder
  end

  def parse_condition
    ConditionParser.new(@report_query.condition).parse do |current_token|
      query_filters[current_token]
    end
  end

  def query_filters
    results = {}

    @report_query.condition_fields.each do |condition_field|
      condition_field_id = condition_field["id"]
      if(condition_field["operator"] == "=" )
        results[condition_field_id] = self.query_filter_term(condition_field)
      else
        results[condition_field_id] = self.query_filter_range(condition_field)
      end
    end

    results
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
        field_id => {
          operator_type => value
        }
      }
    }
  end

  def query_filter_term(condition_field)
    field_id = condition_field["field_id"]
    value = condition_field["value"]
    {
      "term" => {
        "properties.#{field_id}" => value
      }
    }
  end

end
