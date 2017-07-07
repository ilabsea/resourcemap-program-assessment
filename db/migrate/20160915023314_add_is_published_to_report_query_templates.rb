class AddIsPublishedToReportQueryTemplates < ActiveRecord::Migration
  def change
    add_column :report_query_templates, :is_published, :boolean, default: true
  end
end
