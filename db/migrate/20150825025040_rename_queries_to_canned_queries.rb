class RenameQueriesToCannedQueries < ActiveRecord::Migration
  def self.up
    rename_table :queries, :canned_queries
  end 
  def self.down
    rename_table :canned_queries, :queries
  end
end
