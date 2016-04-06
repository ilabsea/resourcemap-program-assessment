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

class Field::YesNoField < Field

  def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
    check_presence_of_value(value)
    Field.yes?(value)
  end

  def decode(value)
    Field.yes?(value)
  end

  def decode_from_ui value
    decode value
  end

end
