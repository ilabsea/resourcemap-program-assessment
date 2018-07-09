# == Schema Information
#
# Table name: fields
#
#  id                       :integer          not null, primary key
#  collection_id            :integer
#  layer_id                 :integer
#  name                     :string(255)
#  code                     :string(255)
#  kind                     :string(255)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  config                   :binary(214748364
#  ord                      :integer
#  metadata                 :text
#  is_mandatory             :boolean          default(FALSE)
#  is_enable_field_logic    :boolean          default(FALSE)
#  is_enable_range          :boolean          default(FALSE)
#  is_display_field         :boolean
#  custom_widgeted          :boolean          default(FALSE)
#  is_custom_aggregator     :boolean          default(FALSE)
#  is_criteria              :boolean          default(FALSE)
#  readonly_custom_widgeted :boolean          default(FALSE)
#

class FieldsController < ApplicationController
	before_filter :setup_guest_user, :if => Proc.new { collection && collection.public }
  before_filter :authenticate_user!, :unless => Proc.new { collection && collection.public }

  def index
    options = {}
    options[:snapshot_id] = current_user_snapshot.snapshot.id if !current_user_snapshot.at_present?
    request.env['HTTP_ACCEPT_ENCODING'] = 'gzip'
    render json: collection.visible_layers_for(current_user, options), :root => false
  end
end
