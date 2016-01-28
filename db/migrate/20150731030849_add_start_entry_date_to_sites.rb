class AddStartEntryDateToSites < ActiveRecord::Migration
  def change
  	add_column :sites, :start_entry_date, :datetime
  end
end
