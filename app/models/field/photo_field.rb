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
#

class Field::PhotoField < Field
  def value_type_description
    "photos"
  end

  def value_hint
    "Path to photo."
  end

  # params: value is 2-element array
  #   value[0] - is the filename
  #   value[1] - is the binary string of the image
  def decode_from_ui(value)
    Site::UploadUtils.uploadSingleFile value[0], Base64.decode64(value[1]) if value[1]
    value[0]
  end
end
