class ReportQueryTemplatePdfTask
  @queue = :pdf_queue
  def self.perform options
    ReportQueryTemplatePdf.new(options).create
  end
end
