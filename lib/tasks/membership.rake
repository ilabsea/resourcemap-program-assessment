namespace :membership do
  desc "Remove every member for those user is nil"
  task remove_nil_user: :environment do
    Membership.remove_nil_user
  end
end