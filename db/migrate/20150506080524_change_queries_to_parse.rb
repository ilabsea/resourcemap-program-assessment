class ChangeQueriesToParse < ActiveRecord::Migration
  def up
    rename_column :queries, :queries, :parse
  end

  def down
  end
end
