# == Schema Information
#
# Table name: site_histories
#
#  id               :integer          not null, primary key
#  collection_id    :integer
#  name             :string(255)
#  lat              :decimal(10, 6)
#  lng              :decimal(10, 6)
#  parent_id        :integer
#  hierarchy        :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  properties       :text
#  location_mode    :string(10)       default("automatic")
#  id_with_prefix   :string(255)
#  valid_since      :datetime
#  valid_to         :datetime
#  site_id          :integer
#  uuid             :string(255)
#  user_id          :integer
#  start_entry_date :datetime         default(2016-02-10 04:24:35 UTC)
#  end_entry_date   :datetime         default(2016-02-10 04:24:35 UTC)
#

class SiteHistory < ActiveRecord::Base
  belongs_to :site
  belongs_to :collection

  serialize :properties, Hash

  def store_in(index)
    Site::IndexUtils.store self, site_id, index
  end
end
