# frozen_string_literal: true

module V1
  class CountriesController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Country'

    before_action :set_country, only: [:show, :update, :destroy]

    def index
      @countries = CountriesIndex.new(self)
      render json: @countries.countries, each_serializer: CountrySerializer, links: @countries.links
    end

    def show
      render json: @country, serializer: CountrySerializer, meta: { updated_at: @country.updated_at, created_at: @country.created_at }
    end

    def update
      if @country.update(country_params)
        render json: { messages: [{ status: 200, title: "Country successfully updated!" }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@country.errors, 422), status: 422
      end
    end

    def create
      @country = Country.new(country_params)
      if @country.save
        render json: { messages: [{ status: 201, title: 'Country successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@country.errors, 422), status: 422
      end
    end

    def destroy
      if @country.destroy
        render json: { messages: [{ status: 200, title: 'Country successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@country.errors, 422), status: 422
      end
    end

    private

      def set_country
        @country = Country.find(params[:id])
      end

      def country_params
        params.require(:country).permit(:name, :region_name, :iso, :region_iso, :country_centroid, :region_centroid, :is_active)
      end
  end
end
