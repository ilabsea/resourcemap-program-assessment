class AddIsAggregatorToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :is_aggregator, :boolean, default: false
  end
end
