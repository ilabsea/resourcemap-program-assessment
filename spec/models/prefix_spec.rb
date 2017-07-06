# == Schema Information
#
# Table name: prefixes
#
#  id         :integer          not null, primary key
#  version    :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe Prefix do
  it "should get first next prefix" do
    Prefix.next.version.should == "AA"
  end

  it "should get next prefix" do
    Prefix.create :version => 'AX'
    Prefix.next.version.should == 'AY'
  end

  it "should save prefix after get next prefix" do
    lambda {
      Prefix.next
    }.should change { Prefix.count }.by(1)
  end
end
