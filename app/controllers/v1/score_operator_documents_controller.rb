# frozen_string_literal: true

module V1
  class ScoreOperatorDocumentsController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show, :create]
    load_and_authorize_resource class: 'ScoreOperatorDocument'

    def index
      return render json: { error: 'You must provide an operator' }, status: 400 unless params.dig(:filter, :operator).present?

      super
    end
  end
end
