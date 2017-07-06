class AddFieldReadonlyCustomWidgetedToFields < ActiveRecord::Migration
  def change
    add_column :fields, :readonly_custom_widgeted, :boolean, default: false
  end
end
