class AddFieldToFieldHistories < ActiveRecord::Migration
  def change
    add_column :field_histories, :is_mandatory, :boolean, :default => false
    add_column :field_histories, :is_enable_field_logic, :boolean, :default => false
    add_column :field_histories, :is_enable_range, :boolean, :default => false
    add_column :field_histories, :is_display_field, :boolean
  end
end
