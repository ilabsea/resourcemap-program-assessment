class ReportQuerySearch
  DEFAULT_SIZE = 100
  include ReportQueryBuilder

  attr_accessor :result, :facet
  def initialize(report_query)
    @report_query = report_query
    @index_name = Collection.index_name(@report_query.collection_id)
  end

  # group_by_fields = [10,11]
  # aggregate_fields = [{field_id: 15}, {field_id: 16}]
  # @output {"10" => "Province", "11" => "District", "15" => "Women", "16" => "Affected"}
  def table_fields
    group_by_field_ids = @report_query.group_by_fields
    agg_field_ids = @report_query.aggregate_fields.map{|item| item['field_id']}
    field_ids = agg_field_ids.concat(group_by_field_ids).uniq

    fields = Field.find(field_ids)
    result = {}
    fields.each do |field|
      result[field.id] = field.name
    end
    result
  end

  def query
    result_query = query_builder
    result_query['facets'] = GroupByBuilder.new(@report_query).facet unless @report_query.aggregate_fields.empty?
    result_query['size'] = DEFAULT_SIZE

    Rails.logger.debug { result_query }

    response = Tire.search(@index_name, result_query).results
    @result = response.results.map { |item| item["_source"]["properties"].values.join(", ")}
    @facet = response.facets
    ReportQueryResult.new(@report_query, @facet).normalize
  end
end
