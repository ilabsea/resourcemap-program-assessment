class Query < ActiveRecord::Base
  serialize :conditions, Array
  belongs_to :collection 

end
