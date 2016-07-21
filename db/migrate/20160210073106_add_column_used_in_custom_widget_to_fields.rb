class AddColumnUsedInCustomWidgetToFields < ActiveRecord::Migration
  def change
    add_column :fields, :custom_widgeted, :boolean, default: false
  end
end
