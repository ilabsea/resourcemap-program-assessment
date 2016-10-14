# == Schema Information
#
# Table name: report_query_templates
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  template         :text
#  collection_id    :integer
#  report_query_id  :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  uuid             :string(255)
#  is_published     :boolean          default(TRUE)
#  pdf_in_progress  :boolean          default(FALSE)
#  pdf_requested_at :datetime
#  pdf_completed_at :datetime
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
        template = ReportQueryTemplate.make(template: "<p>test report 1.{report} \n 2.{report}</p>")
        result = template.translate_template("<table>result</table>")
        expect(result).to eq "<p>test report 1.<table>result</table> \n 2.<table>result</table></p>"
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
