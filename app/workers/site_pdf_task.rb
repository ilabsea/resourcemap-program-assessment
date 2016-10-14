class SitePdfTask
  @queue = :site_pdf_queue
  def self.perform options
    SitePdf.new(options).create
  end
end
