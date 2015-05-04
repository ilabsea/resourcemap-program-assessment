class AddFormulaToQuery < ActiveRecord::Migration
  def change
    add_column :queries, :formula, :text
  end
end
