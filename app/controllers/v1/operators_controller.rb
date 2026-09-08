# frozen_string_literal: true

module V1
  class OperatorsController < APIController
    include APIUploads
    include AuthRateLimiting

    skip_before_action :authenticate, only: [:index, :show, :create]
    load_and_authorize_resource class: "Operator"

    rate_limit to: 5, within: 1.hour, only: :create,
      by: -> { request.remote_ip },
      with: -> { render_too_many_requests },
      store: AuthRateLimiting::STORE

    def update
      # When sending the logo empty, it deletes it
      if params.dig("data", "attributes", "logo") == ""
        params["data"]["attributes"]["delete-logo"] = "1"
      end
      super
    end
  end
end
