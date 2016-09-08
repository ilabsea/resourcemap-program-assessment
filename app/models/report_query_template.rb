class ReportQueryTemplate < ActiveRecord::Base
  belongs_to :collection
  belongs_to :report_query
  attr_accessible :name, :template, :report_query_id

  validates :name, :template, presence: true
end
