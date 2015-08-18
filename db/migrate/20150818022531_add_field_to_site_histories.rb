class AddFieldToSiteHistories < ActiveRecord::Migration
  def change
    add_column :site_histories, :user_id, :integer
    add_column :site_histories, :start_entry_date, :datetime, :default => DateTime.now
    add_column :site_histories, :end_entry_date, :datetime, :default => DateTime.now
  end
end
