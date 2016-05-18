require 'resque/tasks'
require 'resque_scheduler/tasks'

task "resque:setup" => :environment do
  ENV['QUEUE'] ||= 'site_pdf_queue,sms_queue,reminder_queue,email_queue,import_queue,index_recreate_queue' 
end
