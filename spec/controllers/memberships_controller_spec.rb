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

describe MembershipsController do
  include Devise::TestHelpers

  let!(:user) { User.make email: 'foo@test.com' }
  let!(:user_2) { User.make email: 'bar@test.com' }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }

  before(:each) { sign_in user }

  describe "search" do
    it "should find users that have membership" do
      get :search, collection_id: collection.id, term: 'bar'
      JSON.parse(response.body).count.should == 0
    end

    it "should find user" do
      get :search, collection_id: collection.id, term: 'foo'
      json = JSON.parse response.body

      json.size.should == 1
      json[0].should == 'foo@test.com'
    end

    context "without term" do
      it "should return all users in the collection" do
        get :search, collection_id: collection.id
        JSON.parse(response.body).count.should == 1
      end
    end
  end
end
