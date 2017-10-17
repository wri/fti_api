# frozen_string_literal: true

module V1
  class FmusController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate, only: :index
    load_and_authorize_resource class: 'Fmu'

    def index
      fmus = Fmu.fetch_all(options_filter)

      if params[:format].present? && params[:format].include?('geojson')
        render json: build_json(fmus)
      else
        # fmus_resources = fmus.map {|x| FmuResource.new(x, context)}
        # render json: JSONAPI::ResourceSerializer.new(FmuResource)
        #                  .serialize_to_hash(fmus_resources)
        super
      end
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
