class ReportCaching < ActiveRecord::Base
  attr_accessible :collection_id, :report_query_id, :is_modified

  belongs_to :collection
  belongs_to :report_query

  after_save :clear_cache, if: :modified?
  after_destroy :clear_cache

  def self.fetch_cache collection_id, report_query_id
    report_caching = get(collection_id, report_query_id).first

    raise "Can't find Reporting Caching with collection: #{collection_id}, report_query: #{report_query_id}" if report_caching.nil?

    report_caching.fetch_cache
  end

  def self.clear_cache_of_collection collection_id
    get(collection_id).each do |report_caching|
      report_caching.is_modified = true
      report_caching.save
    end
  end

  def self.remove collection_id, report_query_id
    get(collection_id, report_query_id).each do |report_caching|
      report_caching.destroy
    end
  end

  def self.get collection_id, report_query_id = nil
    by_collection(collection_id).by_report_query(report_query_id)
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

  private

  def self.by_collection collection_id = nil
    collection_id.present? ? where(collection_id: collection_id) : where("collection_id is not ?", nil)
  end

  def self.by_report_query report_query_id = nil
    report_query_id.present? ? where(report_query_id: report_query_id) : where("report_query_id is not ?", nil)
  end

  def clear_cache
    Rails.cache.delete(key)
  end

  def key
    "query:collection-#{collection.id}_query-#{report_query.id}"
  end

end
