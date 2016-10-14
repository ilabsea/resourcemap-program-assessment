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

  def generate_pdf_from_text text
    options = {collection_id: collection_id,
               name: name,
               text: text,
               uuid: uuid}
    ReportQueryTemplatePdf.new(options).generate_pdf_from_text
  end

  def generate_pdf
    options = {collection_id: collection_id,
               name: name,
               uuid: uuid}
    Resque.enqueue ReportQueryTemplatePdfTask, options
    self.pdf_in_progress = true
    self.pdf_requested_at = Time.zone.now
    self.pdf_completed_at = nil
    self.save
  end

  def mark_pdf_complete
    self.pdf_in_progress = false
    self.pdf_completed_at = Time.zone.now
    self.save
  end
end
