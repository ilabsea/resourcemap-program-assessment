class QueriesController < ApplicationController
	before_filter :authenticate_user!, :except => [:index]
	before_filter :authenticate_collection_admin!, :only => [:create]
  before_filter :fix_conditions, only: [:create, :update]

	def index
		respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb I18n.t('views.collections.index.properties'), collection_path(collection)
        add_breadcrumb I18n.t('views.collections.tab.can_queries'), collection_thresholds_path(collection)
      end
      format.json { render json: queries.to_a }
    end
	end

	def create
    query = queries.new params[:query]
    query.save

    render json: query
	end

  def update
    query = queries.find params[:id]
    query.update_attributes! params[:query]
    query.reload
    render json: query.as_json
  end

  def destroy
    canned_query.destroy
    Resque.enqueue IndexRecreateTask, canned_query.id
    render json: canned_query
  end

  private
  def fix_conditions
    params[:query][:conditions] = params[:query][:conditions].values
  end

end
