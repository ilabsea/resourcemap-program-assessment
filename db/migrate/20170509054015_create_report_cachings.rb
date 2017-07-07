class CreateReportCachings < ActiveRecord::Migration
  def change
    create_table :report_cachings do |t|
      t.integer :collection_id
      t.integer :report_query_id
      t.boolean :is_modified

      t.timestamps
    end

    add_index :report_cachings, [:collection_id, :report_query_id], unique: true
  end
end
