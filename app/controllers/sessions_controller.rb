class SessionsController < Devise::SessionsController
  include Concerns::MobileDeviceDetection
  include Concerns::LoginTrackable
  
  before_filter :prepare_for_mobile, :only => [:new]
  before_filter :captcha_valid, :only => [:create]

  def captcha_valid
    if LoginFailedTracker.reached_max_attemp? request.remote_ip
      unless verify_recaptcha
        build_resource
        flash[:error] = t('views.devise.sessions.verify_recaptcha')
        respond_with_navigational(resource) { render :new }
      end
    end
  end

  def new
    LoginFailedTracker.track(request.remote_ip) if params[:user].present?
    super
  end

  def create
    LoginFailedTracker.clear request.remote_ip if current_user
    super
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

end
