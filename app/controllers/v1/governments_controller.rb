# frozen_string_literal: true

module V1
  class GovernmentsController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Government'

    before_action :set_government, only: [:show, :update, :destroy]

    def index
      @governments = GovernmentsIndex.new(self)
      render json: @governments.governments#, each_serializer: GovernmentSerializer, links: @governments.links
    end

    def show
      render json: @government, serializer: GovernmentSerializer, #include: [:annex_governances, :annex_operators],
             meta: { updated_at: @government.updated_at, created_at: @government.created_at }
    end

    def update
      if @government.update(government_params)
        render json: { messages: [{ status: 200, title: 'Government successfully updated!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@government.errors, 422), status: 422
      end
    end

    def create
      @government = Government.new(government_params)
      if @government.save
        render json: { messages: [{ status: 201, title: 'Government successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@government.errors, 422), status: 422
      end
    end

    def destroy
      if @government.destroy
        render json: { messages: [{ status: 200, title: 'Government successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@government.errors, 422), status: 422
      end
    end


    private

    def set_government
      @government = Government.find(params[:id])
    end

    def government_params
      params.require(:government).permit(:id, :country_id, :government_entity, :details)
    end
  end
end
