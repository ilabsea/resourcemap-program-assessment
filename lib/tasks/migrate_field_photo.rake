namespace :migrate do
  desc "change field photo stored from filename to full url"

  task :field_photo_to_full_url => :environment do
    Site.migrate_photo_field_to_full_url
  end
end