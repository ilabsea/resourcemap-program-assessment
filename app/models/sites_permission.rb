# == Schema Information
#
# Table name: sites_permissions
#
#  id            :integer          not null, primary key
#  membership_id :integer
#  type          :string(255)
#  all_sites     :boolean          default(TRUE)
#  some_sites    :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class SitesPermission < ActiveRecord::Base
  belongs_to :membership
  serialize :some_sites, Array

  after_save :touch_membership_lifespan
  after_destroy :touch_membership_lifespan

  def as_json(options = {})
    super options.merge({except: [:id, :membership_id, :created_at, :updated_at]})
  end

  def self.no_permission
    { read: nil, write: nil }
  end
end
