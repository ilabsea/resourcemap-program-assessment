module Report::CachingConcern
  extend ActiveSupport::Concern

  included do
    after_save :clear_report_caching
    after_destroy :clear_report_caching
  end

  def clear_report_caching
    ReportCaching.clear_cache_of_collection(collection.id)
  end
end
