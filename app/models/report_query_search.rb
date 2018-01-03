class ReportQuerySearch
  include ReportQueryBuilder

  attr_accessor :result, :facet

  def initialize(report_query)
    @report_query = report_query
    @index_name = Collection.index_name(@report_query.collection_id)
  end

  def query
    result_query = query_builder
    result_query['aggs'] = ReportQueryGroupByBuilder.new(@report_query).facet unless @report_query.aggregate_fields.empty?
    result_query['size'] = Settings.max_aggregate_result_size.to_i
    if @report_query.condition_fields.empty? and @report_query.group_by_fields.empty?
      result_query = ignor_null_field result_query
    end
    query_log(result_query)

    client = Elasticsearch::Client.new
    begin
      # {"query"=>{"match_all"=>{}}, "facets"=>{"20530"=>{"terms"=>{"field"=>"20530", "size"=>500}}}}
      response = client.search(index: @index_name, body: result_query)
      @facet = response['aggregations']
      if(response["_shards"]["failed"] > 0)
        errors = []
        response["_shards"]["failures"].each do |failure|
          errors.push(build_error_message(failure))
        end
        return errors.join("")
      else
        ReportQuerySearchResult.new(@report_query, @facet).as_table
      end
    rescue Exception => e
      Rails.logger.error { e }
    end
  end

  def query_log result_query
    Rails.logger.debug { result_query }
  end

  def build_error_message failure
    field_id = failure['reason']['reason'].split(".")[2].split("'")[0].to_i
    field = Field.find field_id  
    if field
      return "<li> Field \"#{field.name}\" can't be aggregate #{failure['reason']['caused_by']['reason']} </li>"
    else
      return "<li> Error-#{failure['reason']['type']} #{failure['reason']['reason']} #{failure['reason']['caused_by']['reason']} that cause #{failure['reason']['caused_by']['type']} exception. </li>"
    end
  end

end
