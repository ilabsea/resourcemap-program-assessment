class AddPrintTemplateToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :print_template, :text
  end
end
