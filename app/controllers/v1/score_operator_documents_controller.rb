# frozen_string_literal: true

module V1
  class ScoreOperatorDocumentsController < APIController
    skip_before_action :authenticate, only: [:index, :show, :create]
    load_and_authorize_resource class: "ScoreOperatorDocument"

    def index
      return render json: {error: "You must provide an operator"}, status: :bad_request if params.dig(:filter, :operator).blank?

      super
    end
  end
end
