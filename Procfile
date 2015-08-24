web: bundle exec rails server
resque: bundle exec rake resque:work queue=sms_queue_lite,reminder_queue_lite,email_queue_lite,import_queue_lite,index_recreate_queue_lite
resque_scheduler: bundle exec rake resque:scheduler
