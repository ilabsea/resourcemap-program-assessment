class RenameFieldsInQueries < ActiveRecord::Migration
  def up
  	rename_column :queries, :isAllSite, :is_all_site
  	rename_column :queries, :isAllCondition, :is_all_condition
  end

  def down
  end
end
