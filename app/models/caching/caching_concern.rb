module Report::CachingConcern
  extend ActiveSupport::Concern

  included do
    # The user that creates/makes changes to this object
    # attr_accessor :user

    # Set to true to stop creating Activities for this object
    after_save :clear_report_caching

    def clear_report_caching
      ReportCaching.clear_cache_of_collection(collection.id)
    end
  end
end
