class ReportQuerySearchResult
  DELIMITER = '___'

  def initialize(report_query, facet_result)
    @report_query = report_query
    @facet_result = facet_result
  end

  def agg_function_types
    return @field_aggregator_mapper unless @field_aggregator_mapper.nil?
    aggregator_mapping = {
      "count" => "count",
      "sum" => "sum",
      "min" => "min",
      "max" => "max",
      "avg" => "mean"
    }
    @field_aggregator_mapper = {}
    @report_query.aggregate_fields.each do |agg_field|
      agg_field_id = agg_field['field_id']
      agg_type = agg_field['aggregator']
      @field_aggregator_mapper[agg_field_id] = aggregator_mapping[agg_type]
    end
    @field_aggregator_mapper
  end

  # "3_district 5_2012" => {house_hold_key: 10, women_key: 20}
  def normalize
    @report_query.group_by_fields.empty? ? normalize_statistical : normalize_term_stats
  end

  def as_table
    transform(normalize)
  end

  # group_by_fields = [10,11]
  # aggregate_fields = [{field_id: 15}, {field_id: 16}]
  # @output [10,11,15,16]
  def table_field_ids
    group_by_field_ids = @report_query.group_by_fields
    agg_field_ids = @report_query.aggregate_fields.map{|item| item['field_id']}
    field_ids = group_by_field_ids.concat(agg_field_ids).uniq
  end

  # group_by_fields = [10,11]
  # aggregate_fields = [{field_id: 15}, {field_id: 16}]
  # @output {"10" => {"name" => "Province", "type" => "int"},
  #          "11" => {"name" => "District", "type" => 'text'}}
  #          "15" => {"name" => "Year", "type" => 'int'}}
  def hash_mapping
    fields = Field.find(table_field_ids)
    result = {}
    fields.each do |field|
      field_id_str = field.id.to_s
      result[field_id_str] = field #{"name" => field.name, "type" => field.type }
    end
    result
  end

  def translate_field_value(field, value)
    field.translate_value(value)
  end

  # {"3.0_district 5 _2012.0"=>{"1019"=>7.0, "1020"=>6.0},
  #  "3.0_district 5 _2011.0"=>{"1019"=>4.0, "1020"=>3.0},
  #  "3.0_district 4 _2015.0"=>{"1019"=>2.0, "1020"=>5.0},
  #  "3.0_district 4 _2014.0"=>{"1019"=>5.0, "1020"=>4.0} }
  # @output [head, body]
  # head = ['province','district', 'year', 'women', 'house_hold']
  # body = [3, 'district-3', 2015, 7, 15]
  def transform(query_normalized)
    hash_mapping_result = hash_mapping
    body = []
    head_fields = []
    grouped_by_field_headers = {}
    first = true # contruct table head from the first record
    total_aggr_fields = {}

    # query_normalized:
    # {"60809___60809___1493251200000"=>
    # {"13251"=>609.0,
    #  "13252"=>341.0 }
    #

    query_normalized.each do |key, agg_values|
      field_values = key.split(ReportQuerySearchResult::DELIMITER)
      row = []
      position = 0 # cache index after loop
      field_values.each do |field_value|
        if(first)
          field_id = @report_query.group_by_fields[position]
          # hash_mapping_result[field_id]
          head_fields << hash_mapping_result[field_id]
          grouped_by_field_headers[field_id] = hash_mapping_result[field_id]
          total_aggr_fields[field_id] = "#{I18n.t('views.report_queries.total')}" if position == 0
        end

        row << translate_field_value(head_fields[position], field_value)
        position +=1
      end

      hash_mapping_result = hash_mapping_result.delete_if { |field_id, _field| grouped_by_field_headers.key?(field_id)} if first

      hash_mapping_result.each do |field_id, field|

        head_fields << field if first

        field_value = translate_field_value(head_fields[position], agg_values[field_id])
        total_aggr_fields[field_id] = total_aggr_fields[field_id] ? (total_aggr_fields[field_id] + field_value) : field_value

        row << field_value

        position += 1
      end

      first = false
      body << row
    end
    head = head_fields.map { |head_field| head_field.name }
    total = total_aggr_fields.map { |key, value| value }
    body.unshift(head).push(total)
  end

  def normalize_term_stats
    results = {}
    @facet_result.each do |key, search_value|
      key_names = key.split(ReportQuerySearchResult::DELIMITER)

      key_result = key_names[0..-2]  # [3, district5]

      agg_key_name = key_names[-1]

      if search_value.has_key?('buckets')
        # 1 grouped by field
        agg_key_name = key

        search_value['buckets'].each do |term|
          builtin_aggre = term['key']
          record_key = (key_result + [builtin_aggre]).join(ReportQuerySearchResult::DELIMITER)  # [3, district5, 2012]

          results[record_key] = results[record_key] || {}

          agg_function_type = agg_function_types[agg_key_name]
          agg_key_value = term['term'][agg_function_type] # type of aggr SUM, COUNT
          results[record_key][agg_key_name] = agg_key_value
        end
      else
        # more than 1 grouped by field
        search_value.each do |k, v|
          next if k == 'doc_count'

          v['buckets'].each do |term|
            builtin_aggre = term['key']
            record_key = (key_result + [builtin_aggre]).join(ReportQuerySearchResult::DELIMITER)  # [3, district5, 2012]

            results[record_key] = results[record_key] || {}

            agg_function_type = agg_function_types[agg_key_name]
            agg_key_value = term['term'][agg_function_type] # type of aggr SUM, COUNT
            results[record_key][agg_key_name] = agg_key_value
          end
        end
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
