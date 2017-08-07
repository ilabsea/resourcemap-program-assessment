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

  def self.memberships(user, collection_id)
    membership = user.memberships.find{|m| m.collection_id == collection_id.to_i}
    site_permissions = membership.try(:sites_permission)
    results = []
    site_permissions.each do |site_permission_arr|
      site_permission = site_permission_arr[1]
      if site_permission
        site_permission.some_sites.each do |permission|
          permission_obj = {collection_id: collection_id, site_id: permission["id"], read: false, write: false}
          permission_obj = SitesPermission.prepare_permission(permission_obj, site_permission.type)
          if(results.length > 0)
            flag = false
            results.each do |item|
              if(item[:site_id] == permission["id"])
                permission_obj = item;
                permission_obj = SitesPermission.prepare_permission(permission_obj, site_permission.type)
                flag = true
                break
              end
            end
            results.push(permission_obj) if flag == false
          else
            results.push(permission_obj)
          end
        end
      end
    end
    results
  end

  def self.prepare_permission(permission_obj, role)
    case role
    when 'NoneSitesPermission'
      permission_obj["none"] = true
    when 'ReadSitesPermission'
      permission_obj["read"] = true
    when 'WriteSitesPermission'
      permission_obj["write"] = true
    else
      permission_obj["none"] = true
    end
    permission_obj
  end

end
