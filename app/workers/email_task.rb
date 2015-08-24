class EmailTask
  @queue = :email_queue_lite

  def self.perform(users_email, message, email_subject)
    SendMailer.notify_email(users_email, message, email_subject).deliver
  end
end
