class AddFieldAttributeToFieldHistory < ActiveRecord::Migration
  def change
  	add_column :field_histories, :custom_widgeted, :boolean, default: false
  	add_column :field_histories, :is_enable_custom_validation, :boolean, :default => false
  	add_column :field_histories, :is_custom_aggregator, :boolean, default: false
  	add_column :field_histories, :is_criteria, :boolean, default: false
  	add_column :field_histories, :readonly_custom_widgeted, :boolean, default: false
  end
end
