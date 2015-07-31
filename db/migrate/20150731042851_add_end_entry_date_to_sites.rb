class AddEndEntryDateToSites < ActiveRecord::Migration
  def change
  	add_column :sites, :end_entry_date, :datetime
  end
end
