# == Schema Information
#
# Table name: report_queries
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  condition_fields :text
#  group_by_fields  :text
#  aggregate_fields :text
#  condition        :string(255)
#  parse_condition  :text
#  collection_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class ReportQuery < ActiveRecord::Base
  serialize :condition_fields, Array
  serialize :group_by_fields, Array
  serialize :aggregate_fields, Array

  validates :name, presence: true
  validates_uniqueness_of :name, :scope => :collection_id

  belongs_to :collection
  has_many :report_query_templates, dependent: :restrict

  attr_accessible :aggregate_fields, :condition,  :condition_fields,
                  :group_by_fields, :name, :parse_condition, :collection_id

  before_save :sanitize_condition
  after_save :build_report_caching
  before_destroy :remove_report_caching

  # (1 or 3)and2
  def sanitize_condition
    condition = ConditionParser.sanitize(condition) if !condition.nil?
  end

  def build_report_caching
    report_caching = ReportCaching.get(collection.id, self.id).first_or_initialize
    report_caching.is_modified = true
    report_caching.save
  end

  def remove_report_caching
    ReportCaching.remove(collection.id, self.id)
  end

end
