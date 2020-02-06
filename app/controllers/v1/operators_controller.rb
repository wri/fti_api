# frozen_string_literal: true

module V1
  class OperatorsController < ApiController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate, only: [:index, :show, :create]
    load_and_authorize_resource class: 'Operator'

    def update
      # When sending the logo empty, it deletes it
      if params.dig('data', 'attributes', 'logo') == ""
        params['data']['attributes']['delete-logo'] = '1'
      end
      super
    end

    def create
      results = super
      parsed_results = JSON.parse(results)
      unless parsed_results['errors']
        operator = Operator.find parsed_results['data']['id']
        MailService.notify_operator_creation(operator)
      end
      results
    end
  end
end
