class ImportMemberTask
  @queue = :import_member_queue

  def self.perform user_id, collection_id, columns_spec
  	begin
       ImportWizard.execute_import_member(user_id, collection_id, columns_spec)
     rescue Exception => ex
       (ImportJob.last_member_for user_id, collection_id).failed(ex)
     end
   end 
end
