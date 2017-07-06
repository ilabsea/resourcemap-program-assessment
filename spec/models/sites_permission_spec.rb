# == Schema Information
#
# Table name: sites_permissions
#
#  id            :integer          not null, primary key
#  membership_id :integer
#  type          :string(255)
#  all_sites     :boolean          default(TRUE)
#  some_sites    :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'spec_helper'

describe SitesPermission do
  it { should belong_to :membership }

  describe "convert to json" do
    its(:to_json) { should_not include "\"id\":" }
    its(:to_json) { should_not include "\"membership_id\":" }
    its(:to_json) { should_not include "\"created_at\":" }
    its(:to_json) { should_not include "\"updated_at\":" }
  end

  it "should have no_permission" do
    SitesPermission.no_permission.should == { read: nil, write: nil }
  end
end
