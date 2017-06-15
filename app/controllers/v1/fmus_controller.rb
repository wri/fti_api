# frozen_string_literal: true

module V1
  class FmusController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: :index
    load_and_authorize_resource class: 'Fmu'

    def index
#      @fmus = FmusIndex.new(self)
#      render json: @fmus.fmus, each_serializer: FmuFullSerializer,
#             include: [:country, :operator],
#             meta: { total_items: @fmus.total_items }, links: @fmus.links

      render json: build_json
    end

    private

    def build_json
      fmus = Fmu.all
      {
          "type": "FeatureCollection",
          "features": fmus.map(&:geojson)
      }
    end

  end
end
