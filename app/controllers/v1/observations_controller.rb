# frozen_string_literal: true

module V1
  class ObservationsController < APIController
    include APIUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: "Observation"

    # TODO This should be moved to the user_permission
    # Only observations with the status "Needs revision" and "Created" can be destroyed
    def destroy
      unless ["Created", "Needs revision"].include? @observation.validation_status
        return render json: {error: "You can only delete observations that are in state <Created> or <Needs revision>"},
          status: :forbidden
      end
      if @observation.destroy
        render status: :no_content
      else
        render json: {error: "Couldn't delete the observation: #{u.errors&.messages}"}
      end
    end
  end
end
