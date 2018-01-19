class ReportQuerySearch

  include ReportQueryBuilder

  attr_accessor :result, :facet
  def initialize(report_query)
    @report_query = report_query
    @index_name = Collection.index_name(@report_query.collection_id)
  end

  def query
    result_query = query_builder
    result_query['facets'] = ReportQueryGroupByBuilder.new(@report_query).facet unless @report_query.aggregate_fields.empty?
    result_query['size'] = Settings.max_aggregate_result_size.to_i

    query_log(result_query)

    response = Tire.search(@index_name, result_query).results
    
    @result = response.results.map { |item| item["_source"]["properties"].values.join(", ")}
    @facet = response.facets
    ReportQuerySearchResult.new(@report_query, @facet).as_table
  end

  def query_log result_query
    Rails.logger.debug { result_query }
  end
end
