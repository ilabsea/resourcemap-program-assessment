require 'spec_helper'

describe Api::V2::SitesController do
  include Devise::TestHelpers
  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection.layers.make }
  let!(:site1) { collection.sites.make }

  before(:each) { sign_in user }

  describe "Create sites" do
    before(:each) do
      user = 'iLab'
      pw = '1c4989610bce6c4879c01bb65a45ad43'
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
    end

    context "with numeric field" do
      context "as integer" do
        let(:numeric) { layer.numeric_fields.make :code => 'numeric' }
        context "when value is integer" do
          it "save site" do
            post_create_site({"#{numeric.id}" => 10})
            expect(response.status).to eq(200)
          end
        end
        context "when value is decimal" do
          it "does not save site" do
            post_create_site({"#{numeric.id}" => 10.5555})
            expect(response.status).to eq(422)
          end
        end
      end
      context "as decimal with digit limit" do
        let(:numeric) { layer.numeric_fields.make(code: 'numeric', config: {digits_precision: "3", allows_decimals: "true"}) }
        context "valid value" do
          [10, 10.5555, 10.123456].each do |value|
            it "save site" do
              post_create_site({"#{numeric.id}" => value})
              expect(response.status).to eq(200)
              json = JSON.parse response.body
              expect(json["properties"]["#{numeric.id}"]).to eq(value)
            end
          end
        end
      end
    end


    context "with yes_no field" do
      let(:yes_no) { layer.yes_no_fields.make :code => 'yes_no'}
      context 'valid value' do
        ['1', 1, 'true', true, 'yes', 'YES'].each do |value|
          it {
            post_create_site({"#{yes_no.id}" => value})
            expect(response.status).to eq(200)

            json = JSON.parse response.body
            expect(json["properties"]["#{yes_no.id}"]).to eq(true)
          }
        end

        ['0', 0, 'false', false, 'no', 'NO', 2].each do |value|
          it {
            post_create_site({"#{yes_no.id}" => value})
            expect(response.status).to eq(200)

            json = JSON.parse response.body
            expect(json["properties"]["#{yes_no.id}"]).to eq(false)
          }
        end
      end
    end

    context "with select_one field" do
      let(:select_one) { layer.select_one_fields.make(code: 'select_one',
        config: {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2,'code' => 'two', 'label' => 'Two'}]} )}

      context "valid value" do
        [1, '1', 'one'].each do |value|
          it {
            post_create_site({"#{select_one.id}" => value})
            expect(response.status).to eq(200)
            json = JSON.parse response.body
            expect(json["properties"]["#{select_one.id}"]).to eq(1)
          }
        end

        [2, '2', 'two'].each do |value|
          it {
            post_create_site({"#{select_one.id}" => value})
            expect(response.status).to eq(200)
            json = JSON.parse response.body
            expect(json["properties"]["#{select_one.id}"]).to eq(2)
          }
        end

      end
      context "invalid value" do
        ['One', 'Two', 'unknown'].each do |value|
          it {
            post_create_site({"#{select_one.id}" => value})
            expect(response.status).to eq(422)
          }
        end
      end
    end

    context "with select_many field" do
      let(:select_many) { layer.select_many_fields.make(code: 'select_many',
        config: {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'},
                                {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} )}
      context "valid value" do

        [[1,2], ['1', '2'], ['1',2], [1, '1'], ['one', 'two']].each do |value|
          it{
            post_create_site({"#{select_many.id}" => value})
            expect(response.status).to eq(200)
          }
        end

        [[1,2], ['1', '2'], ['1',2]].each do |value|
          it {
            post_create_site({"#{select_many.id}" => value})
            json = JSON.parse response.body
            expect(json["properties"]["#{select_many.id}"]).to eq([1, 2])
          }
        end

        [['one', 'two']].each do |value|
          it {
            post_create_site({"#{select_many.id}" => value})
            json = JSON.parse response.body
            expect(json["properties"]["#{select_many.id}"]).to eq([1, 2])
          }
        end

        [['one', 'invalid2']].each do |value|
          it {
            post_create_site({"#{select_many.id}" => value})
            json = JSON.parse response.body
            expect(json["properties"]["#{select_many.id}"]).to eq([1])
          }
        end

      end

      context "invalid value" do
        [['invalid1', 'invalid2'], ['invalid']].each do |value|
          it {
            post_create_site({"#{select_many.id}" => value})
            expect(response.status).to eq(422)
          }
        end
      end
    end

    context "with hierarchy field" do
      config_hierarchy = [{ id: 100, name: 'Dad', sub: [{id: 200, name: 'Son'}, {id: 300, name: 'Bro'}]}]
      let(:hierarchy) { layer.hierarchy_fields.make(code: 'hierarchy',  config: { hierarchy: config_hierarchy }.with_indifferent_access )}
      context "valid value" do
        [200, '200'].each do |value|
          it {
            post_create_site({"#{hierarchy.id}" => value})
            expect(response.status).to eq(200)
            json = JSON.parse response.body
            expect(json["properties"]["#{hierarchy.id}"]).to eq(value)
          }
        end
      end
      context "invalid value" do
        ['dad', 'Dad'].each do |value|
          it {
            post_create_site({"#{hierarchy.id}" => value})
            expect(response.status).to eq(422)
          }
        end
      end
    end

    context "with date field" do
      let(:date) { layer.date_fields.make code: 'date' }
      context "valid value" do
        ['10/27/2016', '27/10/2016', '2016/10/27', '27-10-2016'].each do |value|
          it {
            post_create_site({"#{date.id}" => value})
            expect(response.status).to eq(200)
            json = JSON.parse response.body
            expect(json["properties"]["#{date.id}"]).to eq("2016-10-27T00:00:00Z")
          }
        end
      end
    end

    context "with site field" do
      let(:site_ref) { layer.site_fields.make code: 'site' }
      it {
        post_create_site({"#{site_ref.id}" => site1.id_with_prefix})
        expect(response.status).to eq(200)
        json = JSON.parse response.body
        expect(json["properties"]["#{site_ref.id}"]).to eq(site1.id)
      }
    end

    context "with user field" do
      let(:director) { layer.user_fields.make code: 'user'}
      context "valid value" do
        it {
          post_create_site({"#{director.id}" => user.email})
          expect(response.status).to eq(200)
          json = JSON.parse response.body
          expect(json["properties"]["#{director.id}"]).to eq(user.email)
        }
      end
      context "invalid value" do
        it {
          post_create_site({"#{director.id}" => user.id})
          expect(response.status).to eq(422)
        }
      end
    end

    context "with near by field" do
      locations = [{"code"=>"100", "name"=>"Phnom Penh", "latitude"=>"12.7237", "longitude"=>"104.893997"},
                    {"code"=>"200", "name"=>"Kandal", "latitude"=>"13.8067", "longitude"=>"104.958"}]
      let(:near_by) { layer.location_fields.make(code: 'location', config: {"locations" => locations})}
      it {
        post_create_site({"#{near_by.id}" => 200})
        expect(response.status).to eq(200)
        json = JSON.parse response.body
        expect(json["properties"]["#{near_by.id}"]).to eq(200)
      }
    end

    context "with photo field" do
      let!(:photo) { layer.photo_fields.make :code => 'photo' }
      it {

        post_create_site({"#{photo.id}" => 'http://www.mind-coder.com/example.jpg'})
        p Site.last
        expect(response.status).to eq(200)
        json = JSON.parse response.body
        expect(json["properties"]["#{photo.id}"]).to include("_#{photo.id}.jpg")
      }
    end

  end

  def post_create_site(properties)
    post :create, id: collection.id, "site" => { name: 'Hello', lat: 12.618897, lng: 104.765625, properties: properties}.to_json
  end

end
