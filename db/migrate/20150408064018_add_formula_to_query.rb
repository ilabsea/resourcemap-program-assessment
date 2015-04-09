class AddFormulaToQuery < ActiveRecord::Migration
  def change
    add_column :queries, :formula, :string
  end
end
