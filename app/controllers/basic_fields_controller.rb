class BasicFieldsController < ApplicationController
  def index
    fields = Field.select("id, name, code, kind, custom_widgeted").where(["collection_id = ? AND layer_id = ?", params[:collection_id], params[:layer_id]])
    render json: fields
  end
end
