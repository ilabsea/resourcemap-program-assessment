module Report::CachingConcern
  extend ActiveSupport::Concern

  included do
    after_save :clear_report_caching

    def clear_report_caching
      ReportCaching.clear_cache_of_collection(collection.id || self.id)
    end
  end
end
