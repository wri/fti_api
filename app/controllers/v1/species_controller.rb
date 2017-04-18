# frozen_string_literal: true

module V1
  class SpeciesController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Species'

    before_action :set_species, only: [:show, :update, :destroy]

    def index
      @species = SpeciesIndex.new(self)
      render json: @species.species, each_serializer: SpeciesSerializer, links: @species.links
    end

    def show
      render json: @species, serializer: SpeciesSerializer, include: [:countries],
             meta: { updated_at: @species.updated_at, created_at: @species.created_at }
    end

    def update
      if @species.update(species_params)
        render json: { messages: [{ status: 200, title: "Species successfully updated!" }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@species.errors, 422), status: 422
      end
    end

    def create
      @species = Species.new(species_params)
      if @species.save
        render json: { messages: [{ status: 201, title: 'Species successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@species.errors, 422), status: 422
      end
    end

    def destroy
      if @species.destroy
        render json: { messages: [{ status: 200, title: 'Species successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@species.errors, 422), status: 422
      end
    end

    private

      def set_species
        @species = Species.find(params[:id])
      end

      def species_params
        params.require(:species).permit(:name, :species_class, :sub_species, :species_family,
                                        :species_kingdom, :scientific_name, :cites_status,
                                        :cites_id, :iucn_status, :common_name, country_ids: [])
      end
  end
end
