# frozen_string_literal: true

class OperatorDecorator < BaseDecorator
  def delete_confirmation_text
    if model&.all_observations&.any?
      "The operator has the observations with the ids: #{model.all_observation_ids.join(', ')}.\nIf you want to keep them associated to the operator, please archive the operator instead."
    else
      'Are you sure you want to delete the producer?'
    end
  end
end
