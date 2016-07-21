# == Schema Information
#
# Table name: activities
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  collection_id :integer
#  layer_id      :integer
#  field_id      :integer
#  site_id       :integer
#  data          :binary(214748364
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  item_type     :string(255)
#  action        :string(255)
#

require 'spec_helper'

describe Activity do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }

  it "creates one when collection is created" do
    assert_activity 'collection', 'created',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'data' => {'name' => collection.name},
      'description' => "Collection '#{collection.name}' was created"
  end

  it "creates one when layer is created" do
    Activity.delete_all

    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    assert_activity 'layer', 'created',
      'collection_id' => collection.id,
      'layer_id' => layer.id,
      'user_id' => user.id,
      'data' => {'name' => layer.name, 'fields' => [{'id' => layer.fields.first.id, 'kind' => 'text', 'code' => 'foo', 'name' => 'Foo'}]},
      'description' => "Layer '#{layer.name}' was created with fields: Foo (foo)"
  end

  context "layer changed" do
    it "creates one when layer's name changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

      Activity.delete_all

      layer.name = 'Layer2'
      layer.save!

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'name' => ['Layer1', 'Layer2']}},
        'description' => "Layer 'Layer1' was renamed to '#{layer.name}'"
    end

    it "creates one when layer's field is added" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      layer.update_attributes! fields_attributes: [{kind: 'text', code: 'two', name: 'Two', ord: 2}]

      field = layer.fields.last

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'added' => [{'id' => field.id, 'code' => field.code, 'name' => field.name, 'kind' => field.kind}]}},
        'description' => "Layer 'Layer1' changed: text field 'Two' (two) was added"
    end

    it "creates one when layer's field's code changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one1', name: 'One', ord: 1}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => ['one', 'one1'], 'name' => 'One', 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'One' (one) code changed to 'one1'"
    end

    it "creates one when layer's field's name changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one', name: 'One1', ord: 1}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => 'one', 'name' => ['One', 'One1'], 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'One' (one) name changed to 'One1'"
    end

    it "creates one when layer's field's options changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'select_one', code: 'one', name: 'One', config: {'options' => [{'code' => '1', 'label' => 'One'}]}, ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      begin
        layer.update_attributes! fields_attributes: [{id: field.id, code: 'one', name: 'One', kind: 'select_one', config: {'options' => [{'code' => '2', 'label' => 'Two'}]}, ord: 1}]
      rescue Exception => ex
        puts ex.backtrace
      end

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'changed' => [{'id' => field.id, 'code' => 'one', 'name' => 'One', 'kind' => 'select_one', 'config' => [{'options' => [{'code' => '1', 'label' => 'One'}]}, {'options' => [{'code' => '2', 'label' => 'Two'}]}]}]}},
        'description' => %(Layer 'Layer1' changed: select_one field 'One' (one) options changed from ["One (1)"] to ["Two (2)"])
    end

    it "creates one when layer's field is removed" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}, {kind: 'text', code: 'two', name: 'Two', ord: 2}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, _destroy: true}]

      assert_activity 'layer', 'changed',
        'collection_id' => collection.id,
        'layer_id' => layer.id,
        'user_id' => user.id,
        'data' => {'name' => 'Layer1', 'changes' => {'deleted' => [{'id' => field.id, 'code' => 'two', 'name' => 'Two', 'kind' => 'text'}]}},
        'description' => "Layer 'Layer1' changed: text field 'Two' (two) was deleted"
    end
  end

  it "creates one when layer is destroyed" do
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    Activity.delete_all

    layer.destroy

    assert_activity 'layer', 'deleted',
      'collection_id' => collection.id,
      'layer_id' => layer.id,
      'user_id' => user.id,
      'data' => {'name' => layer.name},
      'description' => "Layer '#{layer.name}' was deleted"
  end

  it "creates one after creating a site" do
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'beds', name: 'Beds', ord: 1}]
    field = layer.fields.first

    Activity.delete_all

    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {field.es_code => 20}, user: user

    assert_activity 'site', 'created',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'site_id' => site.id,
      'data' => {'name' => site.name, 'lat' => site.lat, 'lng' => site.lng, 'properties' => site.properties},
      'description' => "Site '#{site.name}' was created"
  end

  it "creates one after importing a csv" do
    Activity.delete_all

    collection.import_csv user, %(
      resmap-id, name, lat, lng
      1, Site 1, 30, 40
    ).strip

    assert_activity 'collection', 'csv_imported',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'data' => {'sites' => 1},
      'description' => "Import CSV: 1 site were imported"
  end

  context "site changed" do
    let!(:layer) { collection.layers.make user: user, fields_attributes: [{kind: 'numeric', code: 'beds', name: 'Beds', ord: 1}, {kind: 'numeric', code: 'tables', name: 'Tables', ord: 2}, {kind: 'text', code: 'text', name: 'Text', ord: 3}] }
    let(:beds) { layer.fields.first }
    let(:tables) { layer.fields.second }
    let(:text) { layer.fields.third }

    it "creates one after changing one site's name" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.name = 'Bar'
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => 'Foo', 'changes' => {'name' => ['Foo', 'Bar']}, 'lat' => 10.0, 'lng' => 20.0, 'properties' => {beds.es_code => 20}},
        'description' => "Site 'Foo' was renamed to 'Bar'"
    end

    it "creates one after changing one site's location" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = 15.0
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [10.0, 15.0], 'lng' => [20.0, 20.0]}, 'lat' => 15.0, 'lng' => 20.0, 'properties' => {beds.es_code => 20}},
        'description' => "Site '#{site.name}' changed: location changed from (10.0, 20.0) to (15.0, 20.0)"
    end

    it "creates one after adding location in site without location" do
      site = collection.sites.create! name: 'Foo', properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = 15.0
      site.lng = 20.0

      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [ nil, 15.0], 'lng' => [nil, 20.0]}, 'lat' => 15.0, 'lng' => 20.0, 'properties' => {beds.es_code => 20}},
        'description' => "Site '#{site.name}' changed: location changed from (nothing) to (15.0, 20.0)"
    end

    it "creates one after removing location in site with location" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = nil
      site.lng = nil

      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'lat' => [10.0, nil], 'lng' => [20.0, nil]}, 'lat' => nil, 'lng' => nil, 'properties' => {beds.es_code => 20}},
        'description' => "Site '#{site.name}' changed: location changed from (10.0, 20.0) to (nothing)"
    end

    it "creates one after adding one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{}, {beds.es_code => 30}]}, 'lat' => 10.0, 'lng' => 20.0, 'properties' => {beds.es_code => 30}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from (nothing) to 30"
    end

    it "creates one after changing one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{beds.es_code => 20}, {beds.es_code => 30}]}, 'lat' => 10.0, 'lng' => 20.0, 'properties' => {beds.es_code => 30}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from 20 to 30"
    end

    it "creates one after changing many site's properties" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20, text.es_code => 'foo'}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties[beds.es_code] = 30
      site.properties[text.es_code] = 'bar'
      site.save!

      assert_activity 'site', 'changed',
        'collection_id' => collection.id,
        'user_id' => user.id,
        'site_id' => site.id,
        'data' => {'name' => site.name, 'changes' => {'properties' => [{beds.es_code => 20, text.es_code => 'foo'}, {beds.es_code => 30, text.es_code => 'bar'}]}, 'lat' => 10.0, 'lng' => 20.0, 'properties' => {beds.es_code => 30, text.es_code => 'bar'}},
        'description' => "Site '#{site.name}' changed: 'beds' changed from 20 to 30, 'text' changed from 'foo' to 'bar'"
    end

    it "doesn't create one after siglaning properties will change but they didn't change" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.save!

      Activity.count.should eq(0)
    end

    it "doesn't create one if lat/lng updated but not changed" do
      site = collection.sites.create! name: 'Foo', lat: "-1.9537", lng: "30.10309", properties: {beds.es_code => 20}, user: user

      Activity.delete_all

      site.lat = "-1.9537"
      site.lng = "30.103090000000066"
      site.save!

      Activity.count.should eq(0)
    end
  end

  it "creates one after destroying a site" do
    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, location_mode: :manual, user: user

    Activity.delete_all

    site.destroy

    assert_activity 'site', 'deleted',
      'collection_id' => collection.id,
      'user_id' => user.id,
      'site_id' => site.id,
      'data' => {'name' => site.name},
      'description' => "Site '#{site.name}' was deleted"
  end

  def assert_activity(item_type, action, options = {})
    activities = Activity.all
    activities.length.should eq(1)

    activities[0].item_type.should eq(item_type)
    activities[0].action.should eq(action)
    options.each do |key, value|
      activities[0].send(key).should eq(value)
    end
  end
  
  describe "migrate data" do
    before(:each) do
      TSite = Struct.new(:id, :name, :lat, :lng,  :properties)
      TActivity = Struct.new :user, :site, :data, :item_type, :action, :created_at, :save
      @user = User.make
      @site1 = TSite.new(10, "Kampong Pou" , 10.30, 15.30 , "120" => "channa@info", "145" => "10" , "290" => "20", "310" => "097555")
      
      @field = {
        "120" => "Email",
        "145" => "No Bed",
        "290" => "No Doctor",
        "310" => "Phone"
      }
      
      now = Date.current

      activity4 = TActivity.new  @user, @site1, {
                                          "name"=>"Kampong Pou", 
                                          "changes"=>{"properties"=>[
                                              {"120"=> "tola@gmail", "145"=> "200" }, 
                                              {"120"=> "channa@info", "145"=> "10" }
                                           ]} }, "site", "changed", now-1.day

      activity3 = TActivity.new @user,@site1,  {
                                          "name"=>"Kampong Pou", 
                                          "changes"=>{"properties"=>[
                                              {"120"=> "vicheka@gmail", "290" => "90" }, 
                                              {"120"=> "tola@gmail", "290" => "20" }
                                           ]} },  "site",  "changed", now-2.day
                                        
                                        
      activity2 = TActivity.new @user, @site1,{
                                          "name"=>"Kampong Pou", 
                                          "changes"=>{"properties"=>[
                                              {"120"=> "theary@gmail", "290" => "100" }, 
                                              {"120"=> "vicheka@gmail", "290" => "90" }
                                           ]} },  "site", "changed", now-3.day
                                        
      activity1 = TActivity.new  @user, @site1, {
                                          "name"=>"Kampong Pou", 
                                          "changes"=>{ 
                                            "lat"=>[15.90 , 10.30], 
                                            "lng"=>[50.30 , 15.30]}
                                           },"site",  "changed", now- 4.day
      
      activity0 = TActivity.new @user, @site1, {
                                          "name"=>"Champa", 
                                          "changes"=>{
                                             "name" => ["Champa", "Kampong Pou"]
                                             }
                                           },"site",  "changed", now- 5.day
      
      @activities = [ activity4, activity3, activity2, activity1 , activity0]
 
    end
    
    it "should migrate activities log for site to add incremental properties something" do
       activities = Activity.migrate_activities_of_site(@activities, @site1)
       
       activities.size.should eq 5
       
       activities[0].data["properties"].should eq({"120"=>"channa@info", "145"=>"10", "290"=>"20", "310"=>"097555"})
       activities[0].data["lat"].should eq 10.30
       activities[0].data["lng"].should eq 15.30
       
      
       activities[1].data["properties"].should eq({"120"=>"tola@gmail", "145"=>"200", "290"=>"20", "310"=>"097555"})
       activities[1].data["lat"].should eq 10.30
       activities[1].data["lng"].should eq 15.30
       
       activities[2].data["properties"].should eq({"120"=>"vicheka@gmail", "145"=>"200", "290"=>"90", "310"=>"097555"})
       activities[2].data["lat"].should eq 10.30
       activities[2].data["lng"].should eq 15.30
       
      
       activities[3].data["properties"].should eq({"120"=>"theary@gmail", "145"=>"200", "290"=>"100", "310"=>"097555"})
       activities[3].data["lat"].should eq 10.30
       activities[3].data["lng"].should eq 15.30
      
       activities[4].data["properties"].should eq({"120"=>"theary@gmail", "145"=>"200", "290"=>"100", "310"=>"097555"})
       activities[4].data["lat"].should eq 15.90
       activities[4].data["lng"].should eq 50.30
       activities[4].data["name"].should eq "Champa"

    end
  end
end
