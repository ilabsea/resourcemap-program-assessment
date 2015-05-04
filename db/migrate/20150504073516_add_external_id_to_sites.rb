class AddExternalIdToSites < ActiveRecord::Migration
  def change
  	add_column :sites, :external_id, :string
  end
end
