class TinymceAssetsController < ApplicationController

  def create
    file = params[:file]
    file_name = "#{DateTime.now.to_i}_#{file.original_filename}"
    file_data = file.read.to_s
    image = Site::UploadUtils.uploadTinyMceFile(file_name, file_data)

    render json: {
      image: {
        url: "#{Settings.full_host}/tinymce_photo/#{file_name}"
      }
    }, content_type: "text/html"

    rescue => ex
      render json: {error: {message: "Invalid file type. Only .jpg, .png and .gif allowed"}}, content_type: "text/html"
  end
end
