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

  belongs_to :collection
  has_many :templates, class_name: 'ReportQueryTemplate', dependent: :destroy

  attr_accessible :aggregate_fields, :condition,  :condition_fields,
                  :group_by_fields, :name, :parse_condition

  before_save :sanitize_condition


  # (1 or 3)and2
  def sanitize_condition
    self.condition = ConditionParser.sanitize(self.condition)
  end

end
