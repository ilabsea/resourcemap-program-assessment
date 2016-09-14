# == Schema Information
#
# Table name: report_query_templates
#
#  id              :integer          not null, primary key
#  name            :string(255)
#  template        :text
#  collection_id   :integer
#  report_query_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  uuid            :string(255)
#

require 'spec_helper'

describe ReportQueryTemplate do
  describe '#has_report_place_holder' do
    context "template contains report place holder" do
      it "return true" do
        template = ReportQueryTemplate.make(template: 'test report {report}')
        expect(template.has_report_place_holder?).to eq true
      end
    end

    context 'template does not contain report place holder' do
      it "return false" do
        template = ReportQueryTemplate.make(template: 'test report')
        expect(template.has_report_place_holder?).to eq false
      end

    end
  end

  describe '#translate_template' do
    context "template contains report place holder" do
      it "return a string translated by the translation " do
        template = ReportQueryTemplate.make(template: "test report 1.{report} \n 2.{report}")
        result = template.translate_template("<h1>result</h1>")
        expect(result).to eq "test report 1.<h1>result</h1> \n 2.<h1>result</h1>"
      end
    end

    context "template does not contain report place holder" do
      it "return a string translated by the translation " do
        template = ReportQueryTemplate.make(template: 'test report}')
        result = template.translate_template("<h1>result</h1>")
        expect(result).to eq "test report}"
      end
    end

  end
end
