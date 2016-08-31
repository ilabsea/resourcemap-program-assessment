# == Schema Information
#
# Table name: report_queries
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  condition_fields :text
#  group_by_fields  :text
#  aggregate_fields :text
#  condition        :string(255)
#  parse_condition  :text
#  collection_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class ReportQueriesController < ApplicationController
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
      format.json { render json: report_queries }
    end
  end

  def create
    query = report_queries.new params[:query]
    query.save

    render json: query
	end

  def update
    query = report_queries.find params[:id]
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
