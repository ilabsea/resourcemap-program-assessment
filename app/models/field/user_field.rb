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

class Field::UserField < Field
  def value_type_description
    "email addresses"
  end

  def error_description_for_invalid_values(exception)
    "don't match any email address of a member of this collection"
  end

  def valid_value?(user_email, site=nil)
    check_user_exists(user_email)
  end

	private

	def check_user_exists(user_email)
    user_emails = collection.users.map {|u| u.email}

    if !user_emails.include? user_email
      raise "Non-existent user email address in field #{code}"
    end
    true
  end
end
