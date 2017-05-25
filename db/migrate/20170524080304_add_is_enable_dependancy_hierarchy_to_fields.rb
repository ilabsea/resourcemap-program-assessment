class AddIsEnableDependancyHierarchyToFields < ActiveRecord::Migration
  def change
    add_column :fields, :is_enable_dependancy_hierarchy, :boolean, :default => false
  end
end
