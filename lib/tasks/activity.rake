namespace :activity do
  desc "Remove every activity for those user is nil"
  task remove_nil_user: :environment do
    Activity.remove_nil_user
  end
end
