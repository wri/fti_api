# frozen_string_literal: true

module V1
  class OperatorsController < ApiController
    include ErrorSerializer
    include ApiUploads

    before_action :set_locale, only: [:index, :show]
    after_action  :reset_locale, only: [:index, :show]
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
        MailService.new.notify_operator_creation(operator).deliver
      end
      results
    end

    protected
    
    def set_locale
      I18n.locale = :en
    end

    def reset_locale
      I18n.locale = params[:locale] || I18n.default_locale
    end
  end
end
