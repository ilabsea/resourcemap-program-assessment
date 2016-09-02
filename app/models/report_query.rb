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
  serialize :condition_fields
  serialize :group_by_fields
  serialize :aggregate_fields

  validates :name, presence: true

  belongs_to :collection

  attr_accessible :aggregate_fields, :condition,  :condition_fields,
                  :group_by_fields, :name, :parse_condition

end
