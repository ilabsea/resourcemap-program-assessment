class ReportQueryTemplatePdfsController < ApplicationController
  def create
    report_query_template = ReportQueryTemplate.find_by_uuid(params[:id])
    if(params[:text].present?)
      report_query_template.generate_pdf_from_text(params[:text])
      download_pdf
    else
      report_query_template.generate_pdf
      flash[:notice] = "Pdf is being generated"
      redirect_to collection_report_query_templates_path(report_query_template.collection_id, report_query_template)
    end
  end

  def show
    download_pdf
  end

  private
  def download_pdf
    if report_query_template.is_published
      options = { uuid: report_query_template.uuid, name: report_query_template.name}

      pdf_store_file = ReportQueryTemplatePdf.pdf_store_file(options)
      send_file pdf_store_file, type: 'application/pdf',
                                disposition: 'attachment',
                                filename: pdf_store_file
    else
      raise CanCan::AccessDenied
    end
  end

  def report_query_template
    @report_query_template ||= ReportQueryTemplate.find_by_uuid(params[:id])
  end
end
