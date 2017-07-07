class CreateReportQueries < ActiveRecord::Migration
  def change
    create_table :report_queries do |t|
      t.string :name
      t.text :condition_fields
      t.text :group_by_fields
      t.text :aggregate_fields

      t.string :condition
      t.text :parse_condition

      t.references :collection

      t.timestamps
    end
    add_index :report_queries, :collection_id
  end
end
