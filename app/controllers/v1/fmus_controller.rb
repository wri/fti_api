# frozen_string_literal: true

module V1
  class FmusController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: :index
    load_and_authorize_resource class: 'Fmu'

    def index
      fmus = Fmu.fetch_all(options_filter)
      render json: build_json(fmus)
    end

    private

    def options_filter
      params.permit(:country_ids, :operator_ids)
    end

    def build_json(fmus)
      {
          "type": "FeatureCollection",
          "features": fmus.map(&:geojson)
      }
    end

  end
end
