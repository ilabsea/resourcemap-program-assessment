class AddUuidToReportQueryTemplates < ActiveRecord::Migration
  def change
    add_column :report_query_templates, :uuid, :string
  end
end
