class AddPublishedTemplateToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :is_published_template, :boolean, default: true
  end
end
