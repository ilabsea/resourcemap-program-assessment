# == Schema Information
#
# Table name: site_reminders
#
#  id          :integer          not null, primary key
#  reminder_id :integer
#  site_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class SiteReminder < ActiveRecord::Base
  belongs_to :reminder
  belongs_to :site
end
