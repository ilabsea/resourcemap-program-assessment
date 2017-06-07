# Include this module to get search methods that will modify
# a @search instance that must be a Tire::Search object.
#
# The class that includes this module must provide a collection
# method that returns the collection being searched.
#
# Before executing the search you must invoke apply_queries.
module SearchBase
  def use_codes_instead_of_es_codes
    @use_codes_instead_of_es_codes = true
    self
  end

  def id(id)
    if id.is_a?(Array)
      add_filter terms: {id: id}
    else
      add_filter term: {id: id}
    end
    self
  end

  def name_start_with(name)
    add_filter prefix: {name: name.downcase}
  end

  def name(name)
    add_filter term: {"name.downcase" => name.downcase}
  end

  def name_search(name)
    add_query prefix: {name: name.downcase}
  end

  def uuid(uuid)
    add_filter term: {uuid: uuid}
  end

  def eq(condition_id , field, value)
    if value.blank?
      add_filter missing: {field: field.es_code}
      return self
    end

    query_params = query_params(field, value)
    add_filter query_params

    self
  end

  def not_eq(field, value)
    query_params = query_params(field, value)
    add_filter not: query_params
    self
  end

  def query_params(field, value)
    query_key = field.es_code
    validated_value = field.parse_for_query(value, @use_codes_instead_of_es_codes)

    if field.kind == 'date'
      date_field_range(query_key, validated_value)
    elsif field.kind == 'yes_no' && !validated_value.is_a?(Array) && !Field.yes?(value)
      { not: { :term => { query_key => true }}} # so we return false & nil values
    elsif validated_value.is_a? Array
      { terms: {query_key => validated_value} }
    else
      { term: {query_key => validated_value} }
    end

    # elsif field.select_kind?
    #   {term: {query_key => validated_value}}
    #   add_filter term: {query_key => validated_value}
    # else
    # end

  end

  def date_field_range(key, valid_value)
    date_from = valid_value[:date_from]
    date_to = valid_value[:date_to]

    { range: { key => { gte: date_from, lte: date_to } } }
  end

  def under(field, value)
    if value.blank?
      add_filter missing: {field: field.es_code}
      return self
    end

    # value = field.descendants_of_in_hierarchy value
    if field.find_hierarchy_by_id value
      value = field.descendants_of_in_hierarchy value, false
    elsif field.find_hierarchy_by_name value
      value = field.descendants_of_in_hierarchy value, true
    else
      raise field.invalid_field_message()
    end
    query_key = "properties." + field.es_code
    add_filter terms: {query_key => value}
    self
  end

  def starts_with(condition_id, field, value)
    validated_value = field.apply_format_query_validation(value, @use_codes_instead_of_es_codes)
    query_key = field.es_code
    add_filter key: query_key, value: validated_value, type: :prefix, condition_id: condition_id
    self
  end

  ['lt', 'lte', 'gt', 'gte'].each do |op|
    class_eval %Q(
      def #{op}(condition_id, field, value)
        validated_value = field.apply_format_query_validation(value, @use_codes_instead_of_es_codes)
        field_name = "properties." + field.es_code
        add_filter range: { field_name => {#{op}: validated_value}}
        self
      end
    )
  end

  def op(condition_id, field, op, value)
    case op.to_s.downcase
    when '<', 'l' then lt(condition_id, field, value)
    when '<=', 'lte' then lte(condition_id, field, value)
    when '>', 'gt' then gt(condition_id , field, value)
    when '>=', 'gte' then gte(condition_id, field, value)
    when '=', '==', 'eq' then eq(condition_id, field, value)
    when '!=' then not_eq(field, value)
    when 'under' then under(field, value)
    else raise "Invalid operation: #{op}"
    end
    self
  end

  def where(properties = {})
    properties.each do |condition_id, fieldValue|
      fieldValue.each do |es_code, value|
        case
        when es_code == "location_missing" then location_missing(condition_id)
        when es_code == "updated_since" then after(value, condition_id)
        else
          field = check_field_exists es_code
          if value.is_a? String
            case
            when value[0 .. 1] == '<=' then lte(condition_id, field, value[2 .. -1].strip)
            when value[0] == '<' then lt(condition_id, field, value[1 .. -1].strip)
            when value[0 .. 1] == '>=' then gte(condition_id, field, value[2 .. -1].strip)
            when value[0] == '>' then gt(condition_id, field, value[1 .. -1].strip)
            when value[0] == '=' then eq(condition_id, field, value[1 .. -1].strip)
            when value[0 .. 1] == '~=' then starts_with(condition_id, field, value[2 .. -1].strip)
            else eq(condition_id, field, value)
            end
          elsif value.is_a? Hash
            value.each { |pair| op(condition_id, field, pair[0], pair[1]) }
          else
            eq(condition_id , field, value)
          end
        end
      end
    end
    self
  end

  def date_field_range(key, valid_value, condition_id)
    date_from = valid_value[:date_from]
    date_to = valid_value[:date_to]

    add_filter key: key, value: {gte: date_from, lte: date_to}, type: :range, condition_id: condition_id
    self
  end

  def histogram_search(field_es_code, filters=nil)
    facets_hash = {
      terms: {
        field: field_es_code,
        size: 2147483647,
        all_terms: true,
      }
    }

    if filters.present?
      query_params = query_params(filters.keys.first, filters.values.first)
      query_hash = {facet_filter: {and: [query_params]} }
      facets_hash.merge!(query_hash)
    end

    add_facet "field_#{field_es_code}_ratings", facets_hash

     self
  end

  def before(time)
    time = parse_time(time)
    add_filter range: {updated_at: {lte: Site.format_date(time)}}
    self
  end

  def after(time, condition_id)
    time = parse_time(time)
    updated_since_query(time, condition_id)
  end

  def updated_since(iso_string)
    time = Time.iso8601(iso_string)
    updated_since_query(time)
  end

  def updated_since_query(time, condition_id)
    add_filter key: :updated_at, value: {gte: Site.format_date(time)}, type: :range, condition_id: condition_id
  end

  def alerted_search(v)
    add_filter term: {alert: v}
    self
  end

  def alerted_to_reporter(v)
    @search.filter :term, reporter: v
    self
  end

  def my_site_search id
    @search.filter :term, user_id: id
    self
  end

  def date_query(iso_string, field_name)
    # We use a 2 seconds range, not the exact date, because this would be very restrictive
    time = Time.iso8601(iso_string)
    time_upper_bound = time + 1.second
    time_lower_bound = time - 1.second
    add_filter range: {field_name.to_sym => {gte: Site.format_date(time_lower_bound)}}
    add_filter range: {field_name.to_sym => {lte: Site.format_date(time_upper_bound)}}
    self
  end

  def updated_at(iso_string)
    date_query(iso_string, 'updated_at')
  end

  def created_at(iso_string)
    date_query(iso_string, 'created_at')
  end

  def full_text_search(text)
    query = ElasticSearch::QueryHelper.full_text_search(text, self, collection, fields)
    add_query query_string: {query: query} if query
    self
  end

  def box(west, south, east, north)
    add_filter geo_bounding_box: {
      location: {
        top_left: {
          lat: north,
          lon: west
        },
        bottom_right: {
          lat: south,
          lon: east
        },
      }
    }
    self
  end

  def radius(lat, lng, meters)
    meters = meters.to_f unless meters.is_a?(String) && (meters.end_with?('km') || meters.end_with?('mi'))
    add_filter geo_distance: {
       distance: meters,
       location: { lat: lat, lon: lng }
    }
    self
  end

  def field_exists(field_code)
    add_filter exists: {field: field_code}
  end

  def require_location
    add_filter exists: {field: :location}
    self
  end

  def location_missing(condition_id)
    add_filter not: {exists: {field: :location}}
  end

  def eq_hierarchy(field, value)
    if value.blank?
      @search.filter :missing, {field: field.es_code}
      return self
    end

    validated_value = field.apply_format_query_validation(value, @use_codes_instead_of_es_codes)
    query_key = field.es_code

    if field.kind == 'yes_no'
      @search.filter :term, query_key => Field.yes?(value)
    elsif field.kind == 'date'
      date_field_range(query_key, validated_value)
    elsif field.kind == 'hierarchy' and value.is_a? Array
      @search.filter :terms, query_key => validated_value
    elsif field.select_kind?
      @search.filter :term, query_key => validated_value
    else
      @search.filter :term, query_key => value
    end

    self
  end

  def hierarchy(es_code, value)
    field = check_field_exists es_code
    if value.present?
      eq_hierarchy field, value
    else
      add_filter not: {exists: {field: es_code}}
    end
  end

  def set_formula(formula)
    @formula = formula
  end

  def is_number(str)
    /^[0-9]+$/ === str
  end

  def is_code(str)
    /^[A-Za-z]+$/ === str
  end

  def tokenize
    @formula.split(" ") if @formula
  end

  def parse
    $tokens = tokenize
    $position = 0

    def peek
      if $tokens
        return $tokens[$position]
      end
    end

    def parsePrimaryExpr
      t = peek
      res = {}
      if t == "("
        $position += 1
        res = parseExpr
        $position += 1
      else
        $position += 1
        @filters.each do |f|
          if f[:condition_id] == t
            res = {f[:type]=> {f[:key] => f[:value]}}
            break
          end
        end
      end
      return res
    end

    def parseExpr
      expr = parsePrimaryExpr
      t = peek
      while t == "and" || t == "or" do
        $position += 1
        nextExpr = parsePrimaryExpr
        expr = {t => [expr, nextExpr]}
        t = peek
      end

      return expr
    end

    parseExpr
  end

  def prepare_filter
    if @filters
      expr = parse
      @search.query { |q| q.all}
      @search.filter expr.keys[0] , expr.values[0]
    end
    self
  end

  def get_body
    body = {}

    if @filters
      if @filters.length == 1
        body[:filter] = @filters.first
      else
        body[:filter] = {and: @filters}
       end
    end

    if @facets
      body[:facets] = @facets
    end

    all_queries = []

    if @prefixes
      prefixes = @prefixes.map { |prefix| {prefix: {prefix[:key] => prefix[:value]}} }
      all_queries.concat prefixes
    end

    if @queries
      all_queries.concat @queries
    end

    case all_queries.length
    when 0
      # Nothing to do
    when 1
      body[:query] = all_queries.first
    else
      body[:query] = {bool: {must: all_queries}}
    end

    body
  end

  def select_fields(fields_array)
    @select_fields = fields_array
    self
  end

  def add_filter(filter)
    @filters ||= []
    @filters.push filter
  end

  def add_facet(name, value)
    @facets ||= {}
    @facets[name] = value
  end

  private

  def decode(code)
    return code unless @use_codes_instead_of_es_codes

    code = remove_at_from_code code
    fields.find { |x| x.code == code }.es_code
  end

  def remove_at_from_code(code)
    code.start_with?('@') ? code[1 .. -1] : code
  end

  def add_query(query)
    @queries ||= []
    @queries.push query
  end

  def add_filter(query)
    @filters ||= []
    @filters.push query
  end

  def parse_time(time)
    if time.is_a? String
      time = case time
      when /last(_|\s*)hour/i then Time.now - 1.hour
      when /last(_|\s*)day/i then Time.now - 1.day
      when /last(_|\s*)week/i then Time.now - 1.week
      when /last(_|\s*)month/i then Time.now - 1.month
      else Time.parse(time)
      end
    end
    time
  end

  def check_field_exists(code)
    if @use_codes_instead_of_es_codes
      code = remove_at_from_code code
      fields_with_code = fields.select{|f| f.code == code}
      raise "Unknown field: #{code}" unless fields_with_code.length > 0
      fields_with_code[0]
    else
      fields_with_es_code = fields.select{|f| f.es_code == code}
      raise "Unknown field: #{code}" unless fields_with_es_code.length > 0
      fields_with_es_code[0]
    end
  end

  def fields
    @_fields_ ||= collection.fields
  end

  def to_curl(client, body)
    info = client.transport.hosts.first
    protocol, host, port = info[:protocol], info[:host], info[:port]

    url = "#{protocol}://#{host}:#{port}/#{@index_names}/site/_search"

    body = body.to_json.gsub("'",'\u0027')
    "curl -X GET '#{url}?pretty' -d '#{body}'"
  end
end
