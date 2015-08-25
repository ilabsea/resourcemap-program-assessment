namespace :canned_query do
  desc "form formula rule to canned query"
  task :form_formula => :environment do
    CannedQuery.form_formula
  end
end