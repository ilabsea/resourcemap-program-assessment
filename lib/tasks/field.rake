namespace :field do
  desc "change calculation field variable from $x to ${x}"
  task :fix_calculation_field => :environment do
    Field.all.each do |f|
    	if f.kind == "calculation"
    		all_code = []
        if f.config && f.config["dependent_fields"]
      		f.config["dependent_fields"].each do |index, value|
      			all_code.push value["code"]
      		end
      		all_code = all_code.sort_by(&:length)
      		map = {}
      		all_code.reverse.each do |code|
            if f.config["code_calculation"]
      			 f.config["code_calculation"].gsub! "$#{code}", "${#{code}}"
            end
      		end
        end
    	end
    	f.save!
    end
  end

  desc "migrate invalid code to the valid code"
  task :migrate_code => :environment do
    Field.migrate_code
  end
end
