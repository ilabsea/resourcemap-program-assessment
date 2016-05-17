class SendMailer < ActionMailer::Base
  default from: Settings.default_mail_sender

  def notify_email(users_email, message, email_subject)
    mail(:to => users_email, :subject => email_subject) do |format|
      format.text {render :text => message}
    end
  end
end
