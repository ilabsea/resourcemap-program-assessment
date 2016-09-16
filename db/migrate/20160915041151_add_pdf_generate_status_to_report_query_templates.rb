class AddPdfGenerateStatusToReportQueryTemplates < ActiveRecord::Migration
  def change
    add_column :report_query_templates, :pdf_in_progress, :boolean, default: false
    add_column :report_query_templates, :pdf_requested_at, :datetime
    add_column :report_query_templates, :pdf_completed_at, :datetime
  end
end
