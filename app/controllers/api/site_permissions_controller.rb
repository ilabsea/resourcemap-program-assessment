class Api::SitePermissionsController < ApplicationController
  include Concerns::CheckApiDocs
  include Api::JsonHelper

  before_filter :authenticate_api_user!
  skip_before_filter  :verify_authenticity_token

  def index
    render json: SitesPermission.memberships(current_user, params[:collection_id])
  end


end
