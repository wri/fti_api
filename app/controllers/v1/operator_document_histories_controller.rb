# frozen_string_literal: true

module V1
  class OperatorDocumentHistoriesController < ApiController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'OperatorDocumentHistory'

    def index

      return render json: { error: 'You must provide an operator-id' }, status: :bad_request unless params.dig('filter', 'operator-id').present?
      return render json: { error: 'You must provide a date' }, status: :bad_request unless params.dig('filter', 'date').present?

      super
    end
  end
end
