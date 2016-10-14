class CreateReportQueryTemplates < ActiveRecord::Migration
  def change
    create_table :report_query_templates do |t|
      t.string :name
      t.text :template
      t.references :collection
      t.references :report_query

      t.timestamps
    end
    add_index :report_query_templates, :collection_id
    add_index :report_query_templates, :report_query_id
  end
end
