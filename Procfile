web: bundle exec rails server
resque: bundle exec rake resque:work queue=sms_queue,reminder_queue,email_queue,import_queue,index_recreate_queue,site_pdf_queue
resque_scheduler: bundle exec rake resque:scheduler
