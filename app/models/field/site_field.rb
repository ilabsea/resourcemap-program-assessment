# == Schema Information
#
# Table name: fields
#
#  id                    :integer          not null, primary key
#  collection_id         :integer
#  layer_id              :integer
#  name                  :string(255)
#  code                  :string(255)
#  kind                  :string(255)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  config                :binary(214748364
#  ord                   :integer
#  metadata              :text
#  is_mandatory          :boolean          default(FALSE)
#  is_enable_field_logic :boolean          default(FALSE)
#  is_enable_range       :boolean          default(FALSE)
#  is_display_field      :boolean
#  custom_widgeted       :boolean          default(FALSE)
#  is_custom_aggregator  :boolean          default(FALSE)
#

class Field::SiteField < Field
  def value_type_description
    "site ids"
  end

  def error_description_for_invalid_values(exception)
    "don't match any existing site id in this collection"
  end

  def valid_value?(site_id, site=nil)
    check_site_exists(site_id)
  end


	private

	def check_site_exists(site_id)
    site_ids = collection.sites.map{|s| s.id.to_s}

    if !site_ids.include? site_id.to_s
      raise "Non-existent site-id in field #{code}"
    end
    true
  end

end
