# frozen_string_literal: true

module V1
  class SawmillsController < ApiController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Sawmill'

    def index
      sawmills = Sawmill.fetch_all(options_filter)

      if params[:format].present? && params[:format].include?('geojson')
        render json: build_json(sawmills)
      else
        super
      end
    end

    private

    def options_filter
      params.permit( :operator_ids, :active)
    end

    def build_json(sawmills)
      {
          "type": "FeatureCollection",
          "features": sawmills.map(&:geojson)
      }
    end
  end
end
