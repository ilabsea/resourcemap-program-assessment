require 'resque/tasks'
require 'resque_scheduler/tasks'

task "resque:setup" => :environment do
  ENV['QUEUE'] ||= 'sms_queue_lite,reminder_queue_lite,email_queue_lite,import_queue_lite,index_recreate_queue_lite' 
end
