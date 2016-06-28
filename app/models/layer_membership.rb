class LayerMembership < ActiveRecord::Base
  belongs_to :collection
  belongs_to :user

  after_save :touch_collection_lifespan
  after_destroy :touch_collection_lifespan
  after_save :touch_user_lifespan
  after_destroy :touch_user_lifespan
end
