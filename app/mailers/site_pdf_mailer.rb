class SitePdfMailer < ActionMailer::Base
  default from: "noreply@resourcemap.instedd.org"

  def notify_email(users_email, email_subject, download_url)
    @download_url = download_url
    mail(:to => users_email, :subject => email_subject)
  end
end
