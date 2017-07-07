web: bundle exec rails server
resque: bundle exec rake resque:work queue=sms_queue,reminder_queue,email_queue,import_queue,index_recreate_queue,pdf_queue,import_member_queue
resque_scheduler: bundle exec rake resque:scheduler
