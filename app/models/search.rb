class Search
  include SearchBase

  class Search::Results
    include Enumerable

    attr_reader :sites
    attr_reader :page
    attr_reader :previous_page
    attr_reader :next_page
    attr_reader :total_pages
    attr_reader :total_count

    def initialize(options)
      @sites = options[:sites]
      @page = options[:page]
      @previous_page = options[:previous_page]
      @next_page = options[:next_page]
      @total_pages = options[:total_pages]
      @total_count = options[:total_count]
    end

    def total
      total_count
    end

    def each(&block)
      @sites.each(&block)
    end

    def [](index)
      @sites[index]
    end

    def empty?
      @sites.empty?
    end

    def length
      @sites.length
    end
  end

  attr_accessor :page_size
  attr_accessor :collection

  def initialize(collection, options)
    @collection = collection
    # @search = collection.new_tire_search(options)
    @index_names = collection.index_names_with_options(options)
    @snapshot_id = options[:snapshot_id]
    if options[:current_user]
      @current_user = options[:current_user]
    else
      @current_user = User.find options[:current_user_id] if options[:current_user_id]
    end
    @sort_list = {}
    @from = 0
    @page_size = 50
  end

  def page(page)
    @page = page
    self
  end

  def offset(offset)
    @offset = offset
    self
  end

  def limit(limit)
    @limit = limit
    self
  end

  def sort(es_code, ascendent = true)
    if es_code == 'id' || es_code == 'name' || es_code == 'name_not_analyzed'
      sort = es_code == 'name' ? 'name_not_analyzed' : es_code
    else
      sort = decode(es_code)
    end
    @sort = true
    ascendant = ascendent ? 'asc' : 'desc'
    @sort_list[sort] = ascendant
    self
  end

  def sort_multiple(sort_list)
    sort_list.each_pair do |es_code, ascendent|
      sort(es_code, ascendent)
    end
    self
  end

  def unlimited
    @unlimited = true
    self
  end

  def get_body
    body = super

    if @sorts
      body[:sort] = @sorts
    else
      body[:sort] = 'name.downcase'
    end

    if @select_fields
      body[:fields] = @select_fields
    end

    if @page
      body[:from] = (@page - 1) * page_size
    end

    if @offset && @limit
      body[:from] = @offset
      body[:size] = @limit
    elsif @unlimited
      body[:size] = 1_000_0
    else
      body[:size] = page_size
    end

    body
  end

  def results
    
    body = get_body

    client = Elasticsearch::Client.new

    if Rails.logger.level <= Logger::DEBUG
      Rails.logger.debug to_curl(client, body)
    end

    results = client.search index: @index_names, type: 'site', body: body
    hits = results["hits"]
    sites = hits["hits"]
    total_count = hits["total"]
    # When selecting fields, the results are returned in an array.
    # We only keep the first element of that array.
    if @select_fields
      sites.each do |site|
        fields = site["_source"]["properties"]
        if fields
          fields.each do |key, value|
            fields[key] = value.first if value.is_a?(Array)
          end
        end
      end
    end
    
    results = {sites: sites, total_count: total_count}
    if @page
      results[:page] = @page
      results[:previous_page] = @page - 1 if @page > 1
      results[:total_pages] = (total_count.to_f / page_size).ceil
      if @page < results[:total_pages]
        results[:next_page] = @page + 1
      end
    end
    Results.new(results)
  end

  # Returns the results from ElasticSearch but with codes as keys and codes as
  # values (when applicable).
  def api_results
    visible_fields = @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id)

    fields_by_es_code = visible_fields.index_by &:es_code

    items = results()

    items.each do |item|
      properties = item['_source']['properties']
      item['_source']['identifiers'] = []
      item['_source']['properties'] = {}

      properties.each_pair do |es_code, value|
        field = fields_by_es_code[es_code]
        if field
          item['_source']['properties'][field.code] = field.api_value(value)
        end
      end
    end

    items
  end


  def api_opt_results
    visible_fields = @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id)
    fields_by_es_code = visible_fields.index_by &:es_code
    tire_result = results()

    tire_result.each do |item|
      properties = item['_source']['properties']
      item['_source']['identifiers'] = []
      item['_source']['properties'] = {}

      properties.each_pair do |es_code, value|
        field = fields_by_es_code[es_code]

        if field
          field_value = field.api_value(value)
          item['_source']['properties'][es_code] = field_value
        end
      end
    end
    tire_result
  end

  # Returns the results from ElasticSearch but with the location field
  # returned as lat/lng fields, and the date as a date object
  # def ui_results
  #   # return [] if @source.nil?
  #   fields_by_es_code = @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id).index_by &:es_code

  #   items = results()
  #   return [] if items.empty?
  #   site_ids_permission = @collection.site_ids_permission(@current_user)
  #   items.each do |item|
  #     if item['_source']['location']
  #       item['_source']['lat'] = item['_source']['location']['lat']
  #       item['_source']['lng'] = item['_source']['location']['lon']
  #       item['_source'].delete 'location'
  #     end
  #     item['_source']['created_at'] = Site.parse_time item['_source']['created_at']
  #     item['_source']['updated_at'] = Site.parse_time item['_source']['updated_at']
  #     item['_source']['start_entry_date'] = Site.parse_time(item['_source']['start_entry_date']).strftime("%d/%m/%Y %H:%M:%S")
  #     item['_source']['end_entry_date'] = Site.parse_time(item['_source']['end_entry_date']).strftime("%d/%m/%Y %H:%M:%S")
  #     if not site_ids_permission.include?(item['_source']['id'])
  #       item['_source']['properties'] = item['_source']['properties'].select { |es_code, value|
  #         fields_by_es_code[es_code]
  #       }
  #     end
  #   end

  #   items
  # end

  def ui_results
    fields_by_es_code = @collection.visible_fields_for(@current_user, snapshot_id: @snapshot_id).index_by &:es_code

    results = results()
    results.each do |item|
      if item['_source']['location']
        item['_source']['lat'] = item['_source']['location']['lat']
        item['_source']['lng'] = item['_source']['location']['lon']
        item['_source'].delete 'location'
      end
      item['_source']['created_at'] = Site.parse_time item['_source']['created_at']
      item['_source']['updated_at'] = Site.parse_time item['_source']['updated_at']
      item['_source']['start_entry_date'] = Site.parse_time(item['_source']['start_entry_date']).strftime("%d/%m/%Y %H:%M:%S") if item['_source']['start_entry_date']
      item['_source']['end_entry_date'] = Site.parse_time(item['_source']['end_entry_date']).strftime("%d/%m/%Y %H:%M:%S") if item['_source']['end_entry_date']
      item['_source']['properties'] = item['_source']['properties'].select { |es_code, value|
        fields_by_es_code[es_code]
      }
    end
    results
  end
end
