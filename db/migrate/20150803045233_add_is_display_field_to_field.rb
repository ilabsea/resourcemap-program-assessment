class AddIsDisplayFieldToField < ActiveRecord::Migration
  def change
    add_column :fields, :is_display_field, :boolean
  end
end
