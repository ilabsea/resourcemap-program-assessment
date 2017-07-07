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

class ReadSitesPermission < SitesPermission; end
