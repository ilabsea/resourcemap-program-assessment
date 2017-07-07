# == Schema Information
#
# Table name: field_histories
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
#  valid_since           :datetime
#  valid_to              :datetime
#  field_id              :integer
#  metadata              :text
#  is_mandatory          :boolean          default(FALSE)
#  is_enable_field_logic :boolean          default(FALSE)
#  is_enable_range       :boolean          default(FALSE)
#  is_display_field      :boolean
#

class FieldHistory < ActiveRecord::Base
  include Field::Base
  include Field::TireConcern

  belongs_to :field
  belongs_to :collection
  belongs_to :layer

  serialize :config
  serialize :metadata

  def es_code
    field_id.to_s
  end

  def as_json(options = {})
    { code: code, collection_id: collection_id, config: config, id: field_id, kind: kind, layer_id: layer_id, name: name, ord: ord}
  end
end
