module Api::V1
  class SitePdfsController < ApplicationController
    before_filter :authenticate_api_user!
    skip_before_filter :verify_authenticity_token

    def create
      site = Site.find_by_uuid(params[:id])
      options = {collection_id: site.collection_id, name: site.name, uuid: site.uuid, email: current_user.email}
      Resque.enqueue SitePdfTask, options
      head :ok
    end
  end
end
