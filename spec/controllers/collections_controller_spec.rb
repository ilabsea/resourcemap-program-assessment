# == Schema Information
#
# Table name: collections
#
#  id                    :integer          not null, primary key
#  name                  :string(255)
#  description           :text
#  public                :boolean
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  lat                   :decimal(10, 6)
#  lng                   :decimal(10, 6)
#  min_lat               :decimal(10, 6)
#  min_lng               :decimal(10, 6)
#  max_lat               :decimal(10, 6)
#  max_lng               :decimal(10, 6)
#  icon                  :string(255)
#  quota                 :integer          default(0)
#  is_aggregator         :boolean          default(FALSE)
#  print_template        :text
#  is_published_template :boolean          default(TRUE)
#

require 'spec_helper'

describe CollectionsController do
  include Devise::TestHelpers
  render_views
  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make public: false) }

  before(:each) {sign_in user}


  it "should generate error description form preprocessed hierarchy list" do
    hierarchy_csv = [
      {:order=>1, :error=>"Wrong format.", :error_description=>"Invalid column number"},
      {:order=>2, :id=>"2", :name=>"dad", :sub=>[{:order=>3, :id=>"3", :name=>"son"}]} ]

    res = CollectionsController.generate_error_description_list(hierarchy_csv)

    res.should == "Error: Wrong format. Invalid column number in line 1."
  end

  it "should generate error description form invalid hierarchy list" do
    hierarchy_csv = [{:error=>"Illegal quoting in line 3."}]

    res = CollectionsController.generate_error_description_list(hierarchy_csv)

    res.should == "Error: Illegal quoting in line 3."
  end

  it "should generate error description html form invalid hierarchy list with >1 errors" do
    hierarchy_csv = [
      {:order=>1, :error=>"Wrong format.", :error_description=>"Invalid column number"},
      {:order=>2, :error=>"Wrong format.", :error_description=>"Invalid column number"} ]


    res = CollectionsController.generate_error_description_list(hierarchy_csv)

    res.should == "Error: Wrong format. Invalid column number in line 1.<br/>Error: Wrong format. Invalid column number in line 2."
  end

  it "should not throw error when calling unload_current_snapshot and no snapshot is set" do
    post :unload_current_snapshot, collection_id: collection.id
    assert_nil flash[:notice]
    assert_redirected_to collection_url(collection.id)
  end

  describe "get ES resutls" do
      before(:each) do
        layer = collection.layers.make

        text = layer.text_fields.make :code => 'text'
        numeric = layer.numeric_fields.make :code => 'numeric'

        @site1 = collection.sites.make :name => "site1", :properties => {text.es_code => 'foo', numeric.es_code => 1 }
        @site2 = collection.sites.make :name => "osite2", :properties => {text.es_code => 'bar', numeric.es_code => 2 }
      end

    it "should get json of all field names and codes in a collection" do
      get :sites_by_term, collection_id: collection.id, format: 'json'

      json = JSON.parse response.body
      json.length.should eq(2)
      json[0]["id"].should eq(@site2.id)
      json[0]["name"].should eq(@site2.name)
      json[0]["value"].should eq(@site2.name)
      json[1]["id"].should eq(@site1.id)
      json[1]["name"].should eq(@site1.name)
      json[1]["value"].should eq(@site1.name)
    end

    it "should filter by name in a collection" do
      get :sites_by_term, collection_id: collection.id, format: 'json', term: "o"

      json = JSON.parse response.body
      json.length.should eq(1)
      json[0]["id"].should eq(@site2.id)
      json[0]["name"].should eq(@site2.name)
      json[0]["value"].should eq(@site2.name)
    end
  end

  describe "Permissions" do
    let!(:public_collection) { user.create_collection(Collection.make public: true) }
    let!(:not_member) { User.make }
    let!(:member) { User.make }


    before(:each) do
      sign_out user
      collection.memberships.create! :user_id => member.id, admin: false
      public_collection.memberships.create! :user_id => member.id, admin: false
    end

    it 'should return forbidden in delete if user tries to delete a collection of which he is not member'  do
      sign_in not_member
      delete :destroy, id: collection.id
      response.status.should eq(403)
      delete :destroy, id: public_collection.id
      response.status.should eq(403)
    end

    it 'should return forbidden on delete if user is not collection admin' do
      sign_in member
      delete :destroy, collection_id: collection.id
      response.status.should eq(403)
      delete :destroy, id: public_collection.id
      response.status.should eq(403)
    end

    it 'should return forbidden on create_snapshot if user is not collection admin' do
      sign_in member
      post :create_snapshot, collection_id: public_collection.id, snapshot: {name: 'my snapshot'}
      response.status.should eq(403)
      post :create_snapshot, collection_id: collection.id, snapshot: {name: 'my snapshot'}
      response.status.should eq(403)
    end

  end

  describe "analytic" do 
    it 'should changed user.collection_count by 1' do
      expect{
        post :create, collection: { name: 'collection_1', icon: 'default'}
      }.to change{
        u = User.find user
        u.collection_count
      }.from(0).to(1)

    end
  end

  describe "public access" do
    let!(:public_collection) { user.create_collection(Collection.make public: true) }
    before(:each) { sign_out :user }

    it 'should get index as guest' do
      get :index, collection_id: public_collection.id
      response.should be_success
    end

    it 'should not get index if collection_id is not passed' do
      get :index
      response.should_not be_success
    end
  end

  describe "sites info"  do
    it "gets when all have location" do
      collection.sites.make
      collection.sites.make

      get :sites_info, collection_id: collection.id

      info = JSON.parse response.body
      info["total"].should eq(2)
      info["no_location"].should be_false
    end

    it "gets when some have no location" do
      collection.sites.make
      collection.sites.make
      collection.sites.make lat: nil, lng: nil

      get :sites_info, collection_id: collection.id

      info = JSON.parse response.body
      info["total"].should eq(3)
      info["no_location"].should be_true
    end
  end

end
