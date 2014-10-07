class CreateQueries < ActiveRecord::Migration
  def change
    create_table :queries do |t|
      t.string :name
      t.text :conditions
      t.boolean :isAllSite
      t.boolean :isAllCondition

      t.timestamps
    end
  end
end
