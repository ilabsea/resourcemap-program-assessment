namespace :report_catching do
  desc "clear report catching"
  task :clear => :environment do
    ReportCaching.clear_all_cache
  end
end
