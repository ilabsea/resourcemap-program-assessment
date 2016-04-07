class BasicFieldsController < ApplicationController
  def index
    fields = Field.select("id, name, code, kind").where(["collection_id = ?", params[:collection_id]])
    p fields
    render json: fields
  end
end
