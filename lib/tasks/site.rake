require 'net/http'

namespace :site do
  desc "add the start entry and end entry date to site"
  task :migrate => :environment do
    Site.add_start_and_end_entry_date
  end
end