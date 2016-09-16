class SitePdfTask
  @queue = :pdf_queue
  def self.perform options
    SitePdf.new(options).create
  end
end
