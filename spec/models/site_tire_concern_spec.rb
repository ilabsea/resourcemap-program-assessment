require 'spec_helper'

describe Site::TireConcern do
  let!(:collection) { Collection.make }
  let!(:layer) { collection.layers.make }
  let!(:beds_field) { layer.numeric_fields.make :code => 'beds' }
  let!(:tables_field) { layer.numeric_fields.make :code => 'tables' }
  let!(:threshold) { collection.thresholds.make is_all_site: true, message_notification: "alert", conditions: [ {field: beds_field.es_code, op: 'lt', value: 10} ] }

  it "stores in index after create" do
    site = collection.sites.make :properties => {beds_field.es_code => 10, tables_field.es_code => 20}

    search = Tire::Search::Search.new site.index_name
    results = search.perform.results
    results.length.should eq(1)
    results[0]["_id"].to_i.should eq(site.id)
    results[0]["_source"]["name"].should eq(site.name)
    results[0]["_source"]["lat_analyzed"].should eq(site.lat.to_s)
    results[0]["_source"]["lng_analyzed"].should eq(site.lng.to_s)
    results[0]["_source"]["location"]["lat"].should be_within(1e-06).of(site.lat.to_f)
    results[0]["_source"]["location"]["lon"].should be_within(1e-06).of(site.lng.to_f)
    results[0]["_source"]["properties"][beds_field.es_code].to_i.should eq(site.properties[beds_field.es_code])
    results[0]["_source"]["properties"][tables_field.es_code].to_i.should eq(site.properties[tables_field.es_code])
    Site.parse_time(results[0]["_source"]["created_at"]).to_i.should eq(site.created_at.to_i)
    Site.parse_time(results[0]["_source"]["updated_at"]).to_i.should eq(site.updated_at.to_i)
  end

  it "removes from index after destroy" do
    site = collection.sites.make
    site.destroy

    search = Tire::Search::Search.new site.index_name
    search.perform.results.length.should eq(0)
  end

  it "stores sites without lat and lng in index" do
    group = collection.sites.make :lat => nil, :lng => nil
    site = collection.sites.make

    search = Tire::Search::Search.new collection.index_name
    search.perform.results.length.should eq(2)
  end

  it "should stores alert in index" do
    collection.selected_plugins = ['alerts']
    collection.save
    site = collection.sites.make properties: { beds_field.es_code => 9 }

    search = collection.new_tire_search
    search.filter :term, alert: true
    result = search.perform.results
    result.length.should eq(1)
  end

 end
