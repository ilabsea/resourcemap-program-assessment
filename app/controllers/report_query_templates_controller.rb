# == Schema Information
#
# Table name: report_query_templates
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  template         :text
#  collection_id    :integer
#  report_query_id  :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  uuid             :string(255)
#  is_published     :boolean          default(TRUE)
#  pdf_in_progress  :boolean          default(FALSE)
#  pdf_requested_at :datetime
#  pdf_completed_at :datetime
#

class ReportQueryTemplatesController < ApplicationController
  before_filter :authenticate_user!, except: [:share]
  before_filter :authenticate_collection_admin!, :except => [:index, :show, :share]
  before_filter :render_breadcrumb, :only => [:index, :new, :edit, :show]

  def render_breadcrumb
    show_collection_breadcrumb
    add_breadcrumb I18n.t('views.collections.index.properties'), collection_path(collection)
    add_breadcrumb 'Report Query Template', collection_report_query_templates_path(collection)
  end

  def index
    @report_query_templates = collection.report_query_templates
  end

  def new
    @report_query_template = collection.report_query_templates.build
  end

  def create
    @report_query_template = collection.report_query_templates.build params[:report_query_template]
    if @report_query_template.save
      flash[:notice] = 'Report Template has been created successfully'
      redirect_to collection_report_query_templates_path(collection)
    else
      flash[:alert] = 'Failed to create Report Template'
      render :new
    end
  end

  def edit
    @report_query_template = collection.report_query_templates.find(params[:id])
    add_breadcrumb @report_query_template.name
  end

  def update
    @report_query_template = collection.report_query_templates.find(params[:id])
    if @report_query_template.update_attributes(params[:report_query_template])
      flash[:notice] = 'Report Template has been created successfully'
      redirect_to collection_report_query_templates_path(collection)
    else
      flash[:alert] = 'Failed to create Report Template'
      render :edit
    end
  end

  def destroy
    @report_query_template = collection.report_query_templates.find(params[:id])
    @report_query_template.destroy
    redirect_to collection_report_query_templates_path(collection)
  end

  # GET /:id/report
  def show
    @template = collection.report_query_templates.find_by_uuid(params[:id])
    @report_query = @template.report_query
    @report_result = @template.report_result
    add_breadcrumb @template.name
  end

  def share
    @template = collection.report_query_templates.find_by_uuid(params[:id])
    render layout: "print_template"
  end

end
