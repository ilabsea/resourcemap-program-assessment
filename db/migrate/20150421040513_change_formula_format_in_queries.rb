class ChangeFormulaFormatInQueries < ActiveRecord::Migration
  def up
    change_column :queries, :formula, :text, limit: 2147483647
  end

  def down
    change_column :queries, :formula, :string
  end
end
