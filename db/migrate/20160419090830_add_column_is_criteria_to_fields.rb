class AddColumnIsCriteriaToFields < ActiveRecord::Migration
  def change
    add_column :fields, :is_criteria, :boolean, default: false
  end
end
