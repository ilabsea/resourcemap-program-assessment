class IndexRecreateTask
  @queue = :index_recreate_queue_lite

  def self.perform(collection_id)
    Collection.recreate_site_index(collection_id)
  end
end
