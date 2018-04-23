class ReportQueryTemplatePdf
  def initialize(options)
    @options = options.with_indifferent_access
  end

  def create
    generate_pdf
    send_pdf_link
  end

  def generate_pdf_from_text
    url = Settings.full_host + Rails.application.routes_url_helpers.share_collection_report_query_template_path(collection_id: @options[:collection_id],
                                                                                               id: @options[:uuid], pdf: 1)
    pdf_store_file = ReportQueryTemplatePdf.pdf_store_file(@options)

    temp_store_file = pdf_store_file + ".html"
    File.open(temp_store_file, 'w') do |f|
      f.write(@options[:text])
    end

    command = "wkhtmltopdf -O #{@options[:orientation]} #{temp_store_file} #{pdf_store_file}"
    Rails.logger.debug {command}
    system command
  end

  def generate_pdf_from_multiple_templates
    source_files = ""
    @options[:template_uuids].each do |uuid|
      url = Settings.full_host + Rails.application.routes_url_helpers.share_collection_report_query_template_path(collection_id: @options[:collection_id],
                                                                                                 id: uuid, pdf: 1)

      source_files = source_files + " " + url
    end
    destination_file = ReportQueryTemplatePdf.pdf_report_path(@options)
    command = "wkhtmltopdf -O #{@options[:orientation]} #{source_files} #{destination_file}"
    Rails.logger.debug {command}
    system command
  end

  def generate_pdf
    url = Settings.full_host + Rails.application.routes_url_helpers.share_collection_report_query_template_path(collection_id: @options[:collection_id],
                                                                                               id: @options[:uuid], pdf: 1)
    pdf_store_file = ReportQueryTemplatePdf.pdf_store_file(@options)
    command = "wkhtmltopdf #{url} #{pdf_store_file}"
    Rails.logger.debug {command}
    system command
    template = ReportQueryTemplate.find_by_uuid(@options[:uuid])
    template.mark_pdf_complete
  end

  def send_pdf_link
    url_pdf = Settings.full_host + Rails.application.routes_url_helpers.report_query_template_pdf_path(id: @options[:uuid])
    subject = "PDF document ready for download"
    Resque.enqueue ReportQueryTemplatePdfEmailTask, @options[:email], subject, url_pdf
  end

  def self.pdf_store_file(options)
    filename = "#{options[:name].parameterize}-#{options[:uuid]}.pdf"
    File.join(Rails.root, "public", "print", filename)
  end

  def self.pdf_report_path(options)
    filename = "collection_#{options[:collection_id]}_report.pdf"
    File.join(Rails.root, "public", "print", filename)
  end
end
