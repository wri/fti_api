# frozen_string_literal: true

module V1
  class OperatorDocumentHistoriesController < APIController
    skip_before_action :authenticate, only: [:index, :show]
    before_action :verify_filters, only: :index
    load_and_authorize_resource class: "OperatorDocumentHistory"

    FilterError = Class.new(StandardError)
    rescue_from FilterError, with: :filter_error

    private

    def verify_filters
      filter = params[:filter]

      raise FilterError, "Please add the date and operator-id filters" if filter.blank?
      raise FilterError, "You must provide an operator-id" if filter["operator-id"].blank?
      raise FilterError, "You must provide a date" if filter["date"].blank?
      raise FilterError, "Operator must be an integer" unless filter["operator-id"].to_i.to_s == filter["operator-id"]

      begin
        filter["date"].to_date
      rescue ArgumentError
        raise FilterError, "Invalid date format. Use: YYYY-MM-DD"
      end
    end

    def filter_error(error)
      render json: {error: error.message}, status: :bad_request
    end
  end
end
