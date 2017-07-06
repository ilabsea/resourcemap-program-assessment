namespace :deploy do
  desc "Generate REVISION and VERSION files with the changeset and date of the current revision"
  task :generate_revision_and_version, [:version] do |t, args|
    output = `git log -n1`
    # mercurial_info = Hash[output.split("\n").map { |line| line.split(':', 2).map(&:strip) }]
    mercurial_info = {}
    mercurial_info["changeset"] = "WFP"
   File.open('REVISION', "w+") do |f|
      f.write(mercurial_info["changeset"])
    end

    File.open('VERSION', "w+") do |f|
      f.write(args[:version])
    end
  end
end