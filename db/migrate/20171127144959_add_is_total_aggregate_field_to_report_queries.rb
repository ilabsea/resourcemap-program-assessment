class AddIsTotalAggregateFieldToReportQueries < ActiveRecord::Migration
  def change
  	add_column :report_queries, :is_total_aggregate_field, :boolean, default: false
  end
end
