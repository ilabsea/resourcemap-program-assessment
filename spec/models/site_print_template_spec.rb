require 'spec_helper'

describe SitePrintTemplate do
  describe ".translate" do
    template = <<-eos
      Site name :[Site Name] created by : [Creator]
      List of
      {school_code} {field_code_not_exist}
      <table style="width: 560px; height: 205px; margin-left: auto; margin-right: auto;">
        <tbody>
        <tr>
          <td style="width: 105px;">{age_7_female}</td>
          <td style="width: 105px;">age_7_female}</td>
          <td style="width: 105px;">&nbsp;{age_7_total}</td>
          <td style="width: 105px;">&nbsp;{age_7_total</td>
        </tr>
        </tbody>
      </table>
    eos
    let(:collection) { Collection.make(print_template: template) }
    before(:each) do

      layer_general = collection.layers.make name: 'General'
      layer_student = collection.layers.make name: 'Academic'

      field_school_code = Field::TextField.make(collection: collection, layer: layer_general, name: "school", code: "school_code" )
      field_year = Field::TextField.make(collection: collection, layer: layer_general, name: "year", code: "year")

      field_age_7_female = Field::NumericField.make(collection: collection, layer: layer_student, name: "age_7_female", code: "age_7_female")
      field_age_7_total = Field::NumericField.make(collection: collection, layer: layer_student, name: "age_7_total", code: "age_7_total")


      properties = {
        "#{field_school_code.id}" => "a001",
        "#{field_year.id}" => "2015",
        "#{field_age_7_female.id}" => 20,
        "#{field_age_7_total.id}" => 80
      }
      user = User.make(email: "test@example.com")
      @site = collection.sites.make(name: "PP", properties: properties, user: user)
    end
    context "collection has template expression" do
      it "translate template to value" do
        result = <<-eos
      Site name :PP created by : test@example.com
      List of
      a001 {field_code_not_exist}
      <table style="width: 560px; height: 205px; margin-left: auto; margin-right: auto;">
        <tbody>
        <tr>
          <td style="width: 105px;">20</td>
          <td style="width: 105px;">age_7_female}</td>
          <td style="width: 105px;">&nbsp;80</td>
          <td style="width: 105px;">&nbsp;{age_7_total</td>
        </tr>
        </tbody>
      </table>
        eos
        site_template = SitePrintTemplate.new(@site)
        expect(site_template.translate).to eq result
      end
    end

    context "collection has empty template expression" do
      it "return empty" do
        collection.print_template = ""
        collection.save
        site_template = SitePrintTemplate.new(@site)
        expect(site_template.translate).to be_empty
      end
    end
  end

end
