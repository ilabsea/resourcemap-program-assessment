# == Schema Information
#
# Table name: canned_queries
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  conditions     :text
#  isAllSite      :boolean
#  isAllCondition :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  collection_id  :integer
#  formula        :string(255)
#

class CannedQuery < ActiveRecord::Base
  serialize :conditions, Array
  belongs_to :collection 

  def self.form_formula
    CannedQuery.transaction do
      CannedQuery.find_each(batch_size: 100) do |query|
        rule = ""
        if query.formula == nil
          query.conditions.each_with_index do |condition, index|
            condition_id = index + 1
            condition[:id] = "#{condition_id}"
            if query.conditions.length == 1
              rule = condition[:id]
            else
              if index == query.conditions.length - 1
                rule = rule + condition[:id]
              else
                rule = rule + condition[:id] + " and "
              end
            end
          end
          query.formula = rule
          query.save!
        end
        print "\."
      end
    end
    print 'Done!'  	
  end

end
