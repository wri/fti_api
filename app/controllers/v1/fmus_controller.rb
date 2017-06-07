# frozen_string_literal: true

module V1
  class FmusController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Fmu'

    before_action :set_fmu, only: [:show, :update, :destroy]

    def index
      @fmus = FmusIndex.new(self)
      render json: @fmus.fmus, each_serializer: FmuSerializer,
             meta: { total_items: @fmus.total_items }, links: @fmus.links
    end

    def show
      render json: @fmu, serializer: FmuSerializer, includes: :country , meta: { updated_at: @fmu.updated_at, created_at: @fmu.created_at }
    end

    def update
      if @fmu.update(fmu_params)
        render json: { messages: [{ status: 200, title: 'FMU successfully updated!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@fmu.errors, 422), status: 422
      end
    end

    def create
      @fmu = Fmu.new(fmu_params)
      if @fmu.save
        render json: { messages: [{ status: 201, title: 'FMU successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@fmu.errors, 422), status: 422
      end
    end

    def destroy
      if @fmu.destroy
        render json: { messages: [{ status: 200, title: 'FMU successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@fmu.errors, 422), status: 422
      end
    end

    private

    def set_fmu
      @fmu = Fmu.find(params[:id])
    end

    def fmu_params
      params.require(:fmu).permit(:country_id, :name, :geojson, :operator_id)
    end
  end
end
