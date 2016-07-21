class SitePdf
  def initialize(options)
    @options = options
  end

  def create
    generate_pdf
    send_pdf_link
  end

  def generate_pdf
    url = Settings.full_host + Rails.application.routes_url_helpers.share_collection_site_path(collection_id: @options['collection_id'],
                                                                                               id: @options["uuid"])
    pdf_store_file = SitePdf.pdf_store_file(@options)
    command = "wkhtmltopdf #{url} #{pdf_store_file}"
    system command
  end

  def send_pdf_link
    url_pdf = Settings.full_host + Rails.application.routes_url_helpers.site_pdf_path(id: @options["uuid"])
    subject = "PDF document ready for download"
    Resque.enqueue SitePdfEmailTask, @options["email"], subject, url_pdf
  end

  def self.pdf_store_file(options)
    filename = "#{options["name"].parameterize}-#{options["uuid"]}.pdf"
    File.join(Rails.root, "public", "print", filename)
  end
end
