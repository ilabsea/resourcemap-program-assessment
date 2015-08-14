class SetDefaultEntryDateToSites < ActiveRecord::Migration
  def up
  	change_column :sites, :start_entry_date, :datetime, :default => DateTime.now
  	change_column :sites, :end_entry_date, :datetime, :default => DateTime.now
  end

  def down
  end
end
