class RemoveIsAllSiteFromQueries < ActiveRecord::Migration
  def up
  	remove_column :queries, :is_all_site
  end

  def down
  end
end
