module Api::JsonHelper
  def collection_json(collection, results)
    obj = {}
    obj[:name] = collection.name
    obj[:previousPage] = url_for(params.merge page: results.previous_page, only_path: false) if results.previous_page
    obj[:nextPage] = url_for(params.merge page: results.next_page, only_path: false) if results.next_page
    obj[:count] = results.total
    obj[:totalPages] = results.total_pages
    obj[:sites] = results.map {|result| site_item_json result}
    obj
  end

  def site_item_json(result)
    source = result['_source']

    obj = {}
    obj[:id] = source['id']
    obj[:name] = source['name']
    obj[:createdAt] = Site.parse_time(source['created_at'])
    obj[:updatedAt] = Site.parse_time(source['updated_at'])
    obj[:startEntryDate] = Site.parse_time(source['start_entry_date'])
    obj[:endEntryDate] = Site.parse_time(source['end_entry_date'])
    obj[:user_id] = source['user_id'];
    obj[:collection_id] = source['collection_id'];

    if source['location']
      obj[:lat] = source['location']['lat']
      obj[:long] = source['location']['lon']
    end

    obj[:properties] = source['properties']

    obj
  end
end
