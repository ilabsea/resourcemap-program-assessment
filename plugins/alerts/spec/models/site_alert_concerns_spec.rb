require 'spec_helper'

describe Site::AlertConcerns do 
  let!(:collection) { Collection.make :plugins => {"alerts" => {}} }
  let!(:layer) { collection.layers.make }
  let!(:bed_field) { layer.fields.make :code => 'bed' }
  let!(:phone_field) { layer.fields.make :code => 'phone' } 
  let!(:email_field) { layer.fields.make :code => 'email' } 
  let!(:user_field) { layer.fields.make :code => 'user' } 
  let!(:users) { [User.make(:email => 'user@instedd.org', :password => '1234567', :phone_number => '855123456789'), User.make(:email => 'demo@instedd.org', :password => '1234567', :phone_number => '855123333444')]}
  let!(:site1) { collection.sites.make :properties => { bed_field.es_code => 15, phone_field.es_code => users[0].phone_number, email_field.es_code => users[0].email, user_field.es_code => users[0].email}} 
  
  describe "add new site" do 
    describe "when hit threshold" do
      describe "send email and sms to all selected users_field" do 
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {users: [user_field.es_code]}, phone_notification: {users: [user_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :gt, value: 10 ]}
        let!(:site) {collection.sites.make :properties => {bed_field.es_code => 15, user_field.es_code => users[0].email}}
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([users[0].phone_number], threshold.message_notification).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([users[0].email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end 

      describe "send email and sms to all selected all members" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {members: [users[0].id, users[1].id]}, phone_notification: {members: [users[0].id, users[1].id]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        let!(:site) {collection.sites.make :properties => {bed_field.es_code => 5}}
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([users[0].phone_number, users[1].phone_number], threshold.message_notification).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([users[0].email, users[1].email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end

      describe "send email and sms to all selected fields" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {fields: [email_field.es_code]}, phone_notification: {fields: [phone_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        let!(:site) {collection.sites.make :properties => {bed_field.es_code => 5, phone_field.es_code => users[1].phone_number, email_field.es_code => users[1].email}}
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([users[1].phone_number], threshold.message_notification).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([users[1].email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end
      
      describe "send email and sms to all selected fields, members and users" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {members: [users[0].id], fields: [email_field.es_code], users: [user_field.es_code]}, phone_notification: { members: [users[1].id], fields: [phone_field.es_code], users: [user_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        let!(:site) {collection.sites.make :properties => {bed_field.es_code => 5, phone_field.es_code => users[1].phone_number, email_field.es_code => users[0].email, user_field.es_code => users[0].email}}
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([users[1].phone_number, users[1].phone_number, users[0].phone_number], threshold.message_notification).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([users[0].email, users[0].email, users[0].email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end
    end
  end
  
  describe "edit site" do
    describe "when hit threshold" do
      describe "send email and sms to all selected users_field" do 
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {users: [user_field.es_code]}, phone_notification: {users: [user_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        before(:each) do
          ResqueSpec.reset!
          site1.properties = {bed_field.es_code => 5, user_field.es_code => users[0].email}
          site1.save
        end
        
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([users[0].phone_number], threshold.message_notification).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([users[0].email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end 

      describe "send email and sms to all selected members" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {members: [users[0].id, users[1].id]}, phone_notification: {members: [users[0].id, users[1].id]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 20 ]}
        before(:each) do
          ResqueSpec.reset!
          site1.properties = {bed_field.es_code => 15}
          site1.save 
        end
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([users[0].phone_number, users[1].phone_number], threshold.message_notification).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([users[0].email, users[1].email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end

      describe "send email and sms to all selected fields" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {fields: [email_field.es_code]}, phone_notification: {fields: [phone_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        before(:each) do
          ResqueSpec.reset!
          site1.properties = {bed_field.es_code => 5, phone_field.es_code => users[1].phone_number, email_field.es_code => users[1].email}
          site1.save 
        end
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([users[1].phone_number], threshold.message_notification).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([users[1].email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end
      
      describe "send email and sms to all selected fields, members and users" do
        let!(:threshold){ collection.thresholds.make is_notify: true, is_all_site: true, email_notification: {members: [users[0].id], fields: [email_field.es_code], users: [user_field.es_code]}, phone_notification: { members: [users[1].id], fields: [phone_field.es_code], users: [user_field.es_code]}, message_notification: "alert sms", conditions: [ field: bed_field.es_code, op: :lt, value: 10 ]}
        before(:each) do
          ResqueSpec.reset!
          site1.properties = {bed_field.es_code => 5, phone_field.es_code => users[1].phone_number, email_field.es_code => users[0].email, user_field.es_code => users[0].email}
          site1.save
        end
        it "should add sms_que into Resque.enqueue" do 
          SmsTask.should have_queued([users[1].phone_number, users[1].phone_number, users[0].phone_number], threshold.message_notification).in(:sms_queue)
        end

        it "should add email_que into Resque.enqueue" do 
          EmailTask.should have_queued([users[0].email, users[0].email, users[0].email], threshold.message_notification, "[ResourceMap] Alert Notification").in(:email_queue)
        end
      end
    end
  end
end