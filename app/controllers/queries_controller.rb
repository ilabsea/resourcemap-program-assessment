class QueriesController < ApplicationController
	before_filter :authenticate_user!
	before_filter :authenticate_collection_admin!, :only => [:create]
  before_filter :fix_conditions, only: [:create, :update]
	
	def index
		respond_to do |format|
      format.html
      format.json { render json: queries }      
    end
	end

	def create
    query = queries.new params[:query]
    query.save

    render json: query
	end

  def destroy
    query.destroy
    Resque.enqueue IndexRecreateTask, query.id
    render json: query    
  end

  private
  def fix_conditions
    params[:query][:conditions] = params[:query][:conditions].values
  end

end