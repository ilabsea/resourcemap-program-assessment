class ChangeFormulaFormatToString < ActiveRecord::Migration
  def up
    change_column :queries, :formula, :string
  end

  def down
    change_column :queries, :formula, :text
  end
end
