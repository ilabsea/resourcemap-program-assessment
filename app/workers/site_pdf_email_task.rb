class SitePdfEmailTask
  @queue = :email_queue

  def self.perform(users_email, email_subject, url)
    SitePdfMailer.notify_email(users_email, email_subject, url).deliver
  end
end
