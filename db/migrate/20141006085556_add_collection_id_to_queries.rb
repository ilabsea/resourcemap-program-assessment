class AddCollectionIdToQueries < ActiveRecord::Migration
  def change
  	add_column :queries, :collection_id, :integer, belongs_to: :collections
  end
end
