module Site::ActivityConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_created_activity, :unless => :mute_activities
    before_update :record_name_was, :unless => :mute_activities
    after_update :create_updated_activity, :unless => :mute_activities, :if => :user
    after_destroy :create_deleted_activity, :unless => :mute_activities, :if => :user
  end

  def create_created_activity
    site_data = {'name' => @name_was || name}
    site_data['lat'] = lat if lat
    site_data['lng'] = lng if lng
    site_data['properties'] = properties if properties.present?
    Activity.create! item_type: 'site', action: 'created', collection_id: collection.id, site_id: id, user_id: user.id, data: site_data
  end

  def record_name_was
    @name_was = name_was
  end

  def create_updated_activity

    site_changes = changes.except('updated_at', 'min_lat', 'max_lat', 'min_lng', 'max_lng', 'min_zoom', 'max_zoom').to_hash

    # If either lat or lng change we want to singal a change in both, as in "location changed" and
    # we can show what the location was before and was it now without consulting the site's properties
    site_changes['lat'] = [lat, lat] if !site_changes['lat'] && site_changes['lng']
    site_changes['lng'] = [lng, lng] if site_changes['lat'] && !site_changes['lng']

    unless location_changed(site_changes)
      site_changes.delete 'lat'
      site_changes.delete 'lng'
    end

    # This is the case of properties => [{}, {}]
    if site_changes['properties']
      2.times { |i| site_changes['properties'][i].reject! { |k, v| v.nil? } }
      if site_changes['properties'][0] == site_changes['properties'][1]
        site_changes.delete 'properties'
      end
    end

    if site_changes.present?
      site = Site.find(id)
      Activity.create! item_type: 'site',
                       action: 'changed',
                       collection_id: collection.id,
                       user_id: user.id,
                       site_id: id,
                       data: { "name"     =>  @name_was || name,
                               "changes"  =>  site_changes ,
                               "properties" => site.properties,
                               "lat" =>  site.lat,
                               "lng"  => site.lng
                             }

    end
  end

  def location_changed(changes)
    # This code assumes that 'lat' is a property of 'changes' iff 'lng' is,
    # and that if one is set to/from nil, the other is too.
    if changes['lat']
      if changes['lat'][0] && changes['lat'][1]
        return (changes['lat'][0] - changes['lat'][1]).abs >= 1e-04 ||
               (changes['lng'][0] - changes['lng'][1]).abs >= 1e-04
      else
        return changes['lat'][0] != changes['lat'][1]
      end
    else
      return false
    end
  end

  def create_deleted_activity
    Activity.create! item_type: 'site', action: 'deleted', collection_id: collection.id, user_id: user.id, site_id: id, 'data' => {'name' => name}

    clear_report_caching
  end
end
