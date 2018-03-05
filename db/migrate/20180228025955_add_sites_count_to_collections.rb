class AddSitesCountToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :sites_count, :integer
  end
end
