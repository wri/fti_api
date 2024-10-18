# frozen_string_literal: true

module V1
  class FmusController < APIController
    skip_before_action :authenticate, only: %w[index tiles]
    skip_authorize_resource only: :tiles
    load_and_authorize_resource class: "Fmu"

    def index
      if params[:format].present? && params[:format].include?("geojson")
        fmus = Fmu.fetch_all(options_filter)
        render json: build_json(fmus)
      else
        super
      end
    end

    def tiles
      send_data FmuVectorTile.fetch params[:x], params[:y], params[:z], params[:operator_id]
    end

    private

    def options_filter
      params.permit(:country_ids, :operator_ids, :free)
    end

    def build_json(fmus)
      {
        type: "FeatureCollection",
        features: fmus.map(&:geojson)
      }
    end
  end
end
