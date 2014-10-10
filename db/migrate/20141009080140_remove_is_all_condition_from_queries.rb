class RemoveIsAllConditionFromQueries < ActiveRecord::Migration
  def up
  	remove_column :queries, :is_all_condition
  end

  def down
  end
end
