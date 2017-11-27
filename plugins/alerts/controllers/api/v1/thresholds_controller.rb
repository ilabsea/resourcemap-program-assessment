module Api::V1
  class ThresholdsController < ApplicationController
    def to_reporter
      result = thresholds.select{|t| t.email_notification["to_reporter"] == 'true' }
      render json: result
    end

  end
end
