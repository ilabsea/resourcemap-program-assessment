module Api::V1
  class ThresholdsController < ApplicationController

    def index
      new_thresholds = []
      thresholds.all.each do |threshold|
        new_thresholds << threshold if threshold.email_notification[:to_reporter] == 'true'
      end

      respond_to do |format|
        format.json { render json: new_thresholds }
      end
    end

  end
end
