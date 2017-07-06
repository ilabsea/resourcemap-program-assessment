class BuildReportCachingForReportQuery < ActiveRecord::Migration
  def up
    ReportQuery.find_each do |report_query|
      report_query.build_report_caching
    end
  end

  def down
    ReportQuery.find_each do |report_query|
      report_query.remove_report_caching
    end
  end
end
