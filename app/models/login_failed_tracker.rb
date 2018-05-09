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
  def self.clear ip
    where(:ip_address => ip).destroy_all
  end

  def self.reached_max_attemp? ip
    LoginFailedTracker.where(ip_address: ip).count >= Settings.number_of_attempt_failed
  end

  def self.track ip
    LoginFailedTracker.create(:ip_address => ip, :login_at => Time.now)
  end
end

