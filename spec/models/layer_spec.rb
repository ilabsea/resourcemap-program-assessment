# == Schema Information
#
# Table name: layers
#
#  id            :integer          not null, primary key
#  collection_id :integer
#  name          :string(255)
#  public        :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ord           :integer
#

require 'spec_helper'

describe Layer do
  it { should belong_to :collection }
  it { should have_many :fields }

  let!(:user) { User.make }
  let!(:collection) do
    col = Collection.make
    col.memberships.create! :user_id => user.id, :admin => true
    col
  end

  describe "add_layer_memberships" do
    context "single user in collection" do
      it "does not add layer membership after create" do
        layer = collection.layers.make
        result = LayerMembership.where(user_id: user.id, layer_id: layer.id)
        expect(result.count).to eq(0)

        collection_memberships = collection.memberships
        expect(collection_memberships[0].can_view_other).to eq(false)
        expect(collection_memberships[0].can_edit_other).to eq(false)
        expect(collection_memberships[0].admin).to eq(true)
      end
    end

    context "multiple users in collection" do
      let!(:other_user) { User.make }

      context "with special permission" do
        context "with can_view other permission" do
          it "add layer membership" do
            membership = Membership.make(
              user_id: other_user.id,
              collection_id: collection.id,
              can_view_other: true,
              can_edit_other: false
            )

            layer = collection.layers.make
            layer_membership = collection.layer_memberships.where(user_id: other_user.id).first
            expect(layer_membership.read).to eq true
            expect(layer_membership.write).to eq false
          end
        end

        context "with can_edit other permission" do
          it "add layer membership" do
            membership = Membership.make(
              user_id: other_user.id,
              collection_id: collection.id,
              can_view_other: true,
              can_edit_other: true
            )

            layer = collection.layers.make
            layer_membership = collection.layer_memberships.where(user_id: other_user.id).first
            expect(layer_membership.read).to eq true
            expect(layer_membership.write).to eq true
          end
        end

      end
      context "without special permission" do
        it "does not add layer membership" do
          membership = Membership.make(
            user_id: other_user.id,
            collection_id: collection.id,
            can_view_other: false,
            can_edit_other: false,
            admin: false
          )
          layer = collection.layers.make
          layer_memberships = collection.layer_memberships.where(user_id: other_user.id)
          expect(layer_memberships.count).to eq 0

        end
      end
    end


  end

  def history_concern_class
    described_class
  end

  def history_concern_foreign_key
    described_class.name.foreign_key
  end

  def history_concern_histories
    "#{described_class}_histories"
  end

  it_behaves_like "it includes History::Concern"
end
