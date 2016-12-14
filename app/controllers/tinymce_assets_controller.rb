class TinymceAssetsController < ApplicationController
  def create
    # Take upload from params[:file] and store it somehow...
    # Optionally also accept params[:hint] and consume if needed
    file = params[:file]
    file_name = "#{DateTime.now.to_i}_#{file.original_filename}"
    file_data = file.read.to_s
    image = Site::UploadUtils.uploadTinyMceFile(file_name, file_data)

    render json: {
      image: {
        url: "#{Settings.full_host}/tinymce_photo/#{file_name}"
      }
    }, content_type: "text/html"
  end
end
