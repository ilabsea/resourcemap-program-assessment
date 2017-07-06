class AddIsEnableCustomValidation < ActiveRecord::Migration
  def change
  	add_column :fields, :is_enable_custom_validation, :boolean, :default => false
  end
end
