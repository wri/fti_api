# frozen_string_literal: true

module V1
  class OperatorsController < APIController
    include ErrorSerializer
    include APIUploads

    skip_before_action :authenticate, only: [:index, :show, :create]
    load_and_authorize_resource class: "Operator"

    def update
      # When sending the logo empty, it deletes it
      if params.dig("data", "attributes", "logo") == ""
        params["data"]["attributes"]["delete-logo"] = "1"
      end
      super
    end
  end
end
