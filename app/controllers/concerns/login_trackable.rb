module Concerns::LoginTrackable
  extend ActiveSupport::Concern

  included do
    before_filter :set_reached_max_attemp, only: [:new, :create]
  end

  def set_reached_max_attemp
    @reached_max_failed_attemp = LoginFailedTracker.reached_max_attemp? request.remote_ip
  end

end
