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

  def index
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb I18n.t('views.collections.index.properties'), collection_path(collection)
        add_breadcrumb I18n.t('views.collections.tab.can_queries'), collection_thresholds_path(collection)
      end
      format.json { render json: report_queries.order('id DESC') }
    end
  end

  def create
    query = report_queries.new params[:report_query]
    query.save

    render json: query
	end

  def update
    query = report_queries.find params[:id]
    query.update_attributes! params[:report_query]
    query.reload
    render json: query.as_json
  end

  def destroy
    report_query.destroy
    render json: report_query
  end

end
