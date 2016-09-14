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

class ReportQueryTemplate < ActiveRecord::Base
  REPORT_PLACE_HOLDER = "{report}"

  belongs_to :collection
  belongs_to :report_query
  attr_accessible :name, :template, :report_query_id

  validates :name, :template, presence: true

  before_create :generate_uuid

  def generate_uuid
    self.uuid = UUIDTools::UUID.timestamp_create.to_s
  end

  def has_report_place_holder?
    template.include?(ReportQueryTemplate::REPORT_PLACE_HOLDER)
  end

  def translate_template(translation)
    template.gsub(ReportQueryTemplate::REPORT_PLACE_HOLDER, translation )
  end

  def report_result
    @report_result ||= ReportQuerySearch.new(report_query).query
    @report_result
  end
end
