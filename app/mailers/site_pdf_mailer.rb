class SitePdfMailer < ActionMailer::Base
  default from: Settings.default_mail_sender

  def notify_email(users_email, email_subject, download_url)
    @download_url = download_url
    mail(:to => users_email, :subject => email_subject)
  end
end
