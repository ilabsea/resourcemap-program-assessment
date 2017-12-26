module Api::V1
  class ThresholdsController < ApplicationController
    before_filter :authenticate_api_user!
    skip_before_filter  :verify_authenticity_token

    def to_reporter
      result = thresholds.select{|t| t.notify_to_reporter? }
      render json: result
    end

  end
end
