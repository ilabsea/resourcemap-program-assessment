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
#  is_criteria           :boolean          default(FALSE)
#

class Field::DateField < Field

  def value_type_description
    "dates"
  end

  def value_hint
    "Example of valid date: 1/25/2013."
  end

	def apply_format_query_validation(value, use_codes_instead_of_es_codes = false)
		validated_value = {}
    iso_date_from = decode(parse_date_from(value))
    validated_value[:date_from] =  iso_date_from if valid_value?(iso_date_from)
    iso_date_to = decode(parse_date_to(value))
    validated_value[:date_to] = iso_date_to if valid_value?(iso_date_to)
    validated_value
	end
  
  def decode(m_d_y_value)
    begin
      m_d_y_value.present? ? convert_to_iso8601_string(m_d_y_value) : nil
    rescue
      raise invalid_field_message()
    end
  end

  def decode_from_ui(value)
    begin
      decode(value)
    rescue
      value
    end
  end

  def decode_fred(iso_string_value)
    # FRED API uses iso8601 format in updates, so we dont need to decode any value
    # If this value is not an iso string, an exception will be thrown in the site's validation.
    iso_string_value
  end

  def valid_value?(value, site = nil)
    begin
      time = Time.iso8601(value)
      iso_value = format_date_iso_string(time)
      raise "invalid" unless iso_value == value
    rescue 
      raise invalid_field_message()
    end
    true
  end

  def parse_date(d_m_y_value)
    Time.strptime d_m_y_value, '%d/%m/%Y'
  end

	private

  def invalid_field_message()
    "Invalid date value in field #{code}"
  end

	def convert_to_iso8601_string(m_d_y_value)
    format_date_iso_string(parse_date(m_d_y_value))
  end

  def format_date_iso_string(time)
    time.strftime "%Y-%m-%dT00:00:00Z"
  end

  def parse_date_from(value)
    match = (value.match /(.*),/)
    if match.nil?
      raise invalid_field_message
    end
    match.captures[0]
  end

  def parse_date_to(value)
    match = (value.match /,(.*)/)
    if match.nil?
      raise invalid_field_message
    end
    match.captures[0]
  end


end
