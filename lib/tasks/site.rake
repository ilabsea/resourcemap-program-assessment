require 'net/http'

namespace :site do
  desc "add the start entry and end entry date to sites"
  task :migrate => :environment do
    Site.add_start_and_end_entry_date
  end

  desc "add created_user_id to sites"
  task :add_created_user_id => :environment do
  	Site.add_created_user_id
  end
end