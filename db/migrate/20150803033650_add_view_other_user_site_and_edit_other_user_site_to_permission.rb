class AddViewOtherUserSiteAndEditOtherUserSiteToPermission < ActiveRecord::Migration
  def change
  	add_column :memberships, :can_view_other, :boolean, :default => false
  	add_column :memberships, :can_edit_other, :boolean, :default => false
  end
end
