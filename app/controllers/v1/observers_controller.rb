# frozen_string_literal: true

module V1
  class ObserversController < ApiController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Observer'

    def update
      # When sending the logo empty, it deletes it
      if params.dig('data', 'attributes', 'logo') == ""
        params['data']['attributes']['delete-logo'] = '1'
      end
      super
    end
  end
end
