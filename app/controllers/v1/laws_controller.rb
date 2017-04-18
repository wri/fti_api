# frozen_string_literal: true

module V1
  class LawsController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Law'

    before_action :set_law, only: [:show, :update, :destroy]

    def index
      @laws = LawsIndex.new(self)
      render json: @laws.laws, each_serializer: LawSerializer, links: @laws.links
    end

    def show
      render json: @law, serializer: LawSerializer, meta: { updated_at: @law.updated_at, created_at: @law.created_at }
    end

    def update
      if @law.update(law_params)
        render json: { messages: [{ status: 200, title: "Law successfully updated!" }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@law.errors, 422), status: 422
      end
    end

    def create
      @law = Law.new(law_params)
      if @law.save
        render json: { messages: [{ status: 201, title: 'Law successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@law.errors, 422), status: 422
      end
    end

    def destroy
      if @law.destroy
        render json: { messages: [{ status: 200, title: 'Law successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@law.errors, 422), status: 422
      end
    end

    private

      def set_law
        @law = Law.find(params[:id])
      end

      def law_params
        params.require(:law).permit(:country_id, :vpa_indicator, :legal_reference, :legal_penalty)
      end
  end
end
