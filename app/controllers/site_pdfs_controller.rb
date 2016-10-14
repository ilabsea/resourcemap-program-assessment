class SitePdfsController < ApplicationController
  def create
    site = Site.find_by_uuid(params["id"])
    options = {collection_id: site.collection_id, name: site.name, uuid: site.uuid, email: current_user.email}
    Resque.enqueue SitePdfTask, options
    head :ok
  end

  def show
    site = Site.find_by_uuid(params[:id])
    if site.collection.is_published_template
      pdf_store_file = SitePdf.pdf_store_file "uuid" => site.uuid, "name" => site.name
      send_file pdf_store_file, type: 'application/pdf',
                                disposition: 'attachment',
                                filename: pdf_store_file
    else
      raise CanCan::AccessDenied
    end

  end
end
