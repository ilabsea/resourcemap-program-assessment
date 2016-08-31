# == Schema Information
#
# Table name: site_histories
#
#  id               :integer          not null, primary key
#  collection_id    :integer
#  name             :string(255)
#  lat              :decimal(10, 6)
#  lng              :decimal(10, 6)
#  parent_id        :integer
#  hierarchy        :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  properties       :text
#  location_mode    :string(10)       default("automatic")
#  id_with_prefix   :string(255)
#  valid_since      :datetime
#  valid_to         :datetime
#  site_id          :integer
#  uuid             :string(255)
#  user_id          :integer
#  start_entry_date :datetime         default(2016-05-24 02:28:03 UTC)
#  end_entry_date   :datetime         default(2016-05-24 02:28:03 UTC)
#

require 'spec_helper'

describe SiteHistory do
  it { should belong_to :site }

  it "should create ES index" do
    index_name = Collection.index_name 32, snapshot: "last_year"
    index = Tire::Index.new index_name
    index.create

    site_history = SiteHistory.make

    site_history.store_in index

    index.exists?.should be_true

    search = Tire::Search::Search.new index_name
    search.perform.results.length.should eq(1)
    search.perform.results.first["_source"]["name"].should eq(site_history.name)
    search.perform.results.first["_source"]["id"].should eq(site_history.site_id)
    search.perform.results.first["_source"]["properties"].should eq(site_history.properties)
    search.perform.results.first["_source"]["location"]["lat"].should eq(site_history.lat)
    search.perform.results.first["_source"]["location"]["lon"].should eq(site_history.lng)
  end

end

