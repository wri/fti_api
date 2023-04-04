# frozen_string_literal: true

module V1
  class SawmillsController < APIController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: "Sawmill"

    def index
      if params[:format].present? && params[:format].include?("geojson")
        sawmills = Sawmill.fetch_all(options_filter)
        render json: build_json(sawmills)
      else
        super
      end
    end

    def show
      if params[:format].present? && params[:format].include?("geojson")
        sawmill = Sawmill.find(params[:id])
        render json: build_json([sawmill])
      else
        super
      end
    end

    private

    def options_filter
      params.permit(:operator_ids, :active)
    end

    def build_json(sawmills)
      {
        type: "FeatureCollection",
        features: sawmills.map(&:geojson)
      }
    end
  end
end
