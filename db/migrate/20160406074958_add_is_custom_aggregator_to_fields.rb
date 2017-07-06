class AddIsCustomAggregatorToFields < ActiveRecord::Migration
  def change
    add_column :fields, :is_custom_aggregator, :boolean, default: false
  end
end
