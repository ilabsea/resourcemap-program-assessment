# == Schema Information
#
# Table name: prefixes
#
#  id         :integer          not null, primary key
#  version    :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Prefix < ActiveRecord::Base
  validates_presence_of :version
  validates_uniqueness_of :version
  
  START = 'AA'
  
  def self.next
    prefix = START
    if last_prefix = Prefix.last
      prefix = last_prefix.version.next.gsub("O", "P")				
    end
    Prefix.create :version => prefix
  end

end
