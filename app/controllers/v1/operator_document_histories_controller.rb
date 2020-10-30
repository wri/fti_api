# frozen_string_literal: true

module V1
  class OperatorDocumentHistoriesController < ApiController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'OperatorDocumentHistory'

    def index

      return render json: { error: 'You must provide an operator-id' }, status: :bad_request if params.dig('filter', 'operator-id').blank?
      return render json: { error: 'You must provide a date' }, status: :bad_request if params.dig('filter', 'date').blank?

      super
    end
  end
end
