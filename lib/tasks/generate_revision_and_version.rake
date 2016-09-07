namespace :deploy do
  desc "Generate REVISION and VERSION files with the changeset and date of the current revision"
  task :generate_revision_and_version, [:version] do |t, args|
    File.open('VERSION', "w+") do |f|
      f.write(args[:version])
    end
  end
end