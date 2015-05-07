class AddQueryToQueries < ActiveRecord::Migration
  def change
    add_column :queries, :queries, :text
  end
end
