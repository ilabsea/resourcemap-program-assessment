class AddKindsToImportJob < ActiveRecord::Migration
  def change
  	add_column :import_jobs, :kinds, :text
  end
end
