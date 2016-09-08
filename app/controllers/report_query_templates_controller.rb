class ReportQueryTemplatesController < ApplicationController
  before_filter :authenticate_user!

  def index
    @report_query_templates = collection.report_query_templates.order('id DESC')
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
    template = collection.report_query_templates.find(params[:id])
    report_query = template.report_query
    @report = ReportQuerySearch.new(report_query)
    @report.query

  end

end
