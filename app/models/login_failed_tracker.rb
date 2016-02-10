# == Schema Information
#
# Table name: login_failed_trackers
#
#  id         :integer          not null, primary key
#  login_at   :datetime
#  ip_address :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class LoginFailedTracker < ActiveRecord::Base
end

