# frozen_string_literal: true

module V1
  class FmusController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate, only: %w[index tiles]
    skip_authorize_resource only: :tiles
    load_and_authorize_resource class: 'Fmu'

    def index
      fmus = Fmu.fetch_all(options_filter)

      if params[:format].present? && params[:format].include?('geojson')
        render json: build_json(fmus)
      else
        super
      end
    end

    def tiles
      tile = Fmu.vector_tiles params[:x], params[:y], params[:z]
      send_data tile
    end

    private

    def options_filter
      params.permit(:country_ids, :operator_ids, :free)
    end

    def build_json(fmus)
      {
          "type": "FeatureCollection",
          "features": fmus.map(&:geojson)
      }
    end

  end
end
