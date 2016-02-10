# == Schema Information
#
# Table name: memberships
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  collection_id  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  admin          :boolean          default(FALSE)
#  can_view_other :boolean          default(FALSE)
#  can_edit_other :boolean          default(FALSE)
#

require 'spec_helper'

describe "routes for Memberships" do
  it "should route to search" do
    get("/collections/1/memberships/search").
      should route_to(
        controller: 'memberships', 
        action: 'search', 
        collection_id: '1'
      )
  end
end
