# frozen_string_literal: true

class ObservationReportDecorator < BaseDecorator
  def delete_confirmation_text
    if model&.observations&.any?
      "The report has the observations with the ids: #{model.observation_ids.join(", ")}. Are you sure you want to move it to recycle bin?"
    else
      "Are you sure you want to move this report to recycle bin?"
    end
  end
end
