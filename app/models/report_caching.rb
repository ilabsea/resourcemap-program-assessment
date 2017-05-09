class ReportCaching < ActiveRecord::Base
  attr_accessible :collection_id, :report_query_id, :is_modified

  belongs_to :collection
  belongs_to :report_query

  def self.load_or_cache collection, report_query
    report_caching = get(collection.id, report_query.id).first

    raise "Can't find Reporting Caching with collection: #{collection.id}, report_query: #{report_query.id}" if report_caching.nil?

    report_caching.changed! if report_caching.modified?

    report_caching.fetch_cache
  end

  def self.get collection_id, report_query_id = nil
    by_collection(collection_id).by_report_query(report_query_id)
  end

  def changed!
    clear_cache

    self.is_modified = true
    self.save!
  end

  def clear_cache
    Rails.cache.delete(key)
  end

  def fetch_cache
    report_result = Rails.cache.fetch(key) do
       ReportQuerySearch.new(report_query).query
    end

    update_attributes(is_modified: false)

    report_result
  end

  def modified?
    is_modified
  end

  def key
    "query:collection-#{collection.id}_query-#{report_query.id}"
  end

  private

  def self.by_collection collection_id = nil
    collection_id.present? ? where(collection_id: collection_id) : where("collection_id is not ?", nil)
  end

  def self.by_report_query report_query_id = nil
    report_query_id.present? ? where(report_query_id: report_query_id) : where("report_query_id is not ?", nil)
  end

end
