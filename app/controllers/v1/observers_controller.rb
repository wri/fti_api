# frozen_string_literal: true

module V1
  class ObserversController < ApplicationController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Observer'

    before_action :set_observer, only: [:show, :update, :destroy]

    def index
      @observers = ObserversIndex.new(self)
      render json: @observers.observers, each_serializer: ObserverSerializer, links: @observers.links
    end

    def show
      render json: @observer, serializer: ObserverSerializer, include: [:country, :users],
             meta: { updated_at: @observer.updated_at, created_at: @observer.created_at }
    end

    def update
      if @observer.update(observer_params)
        render json: { messages: [{ status: 200, title: "Monitor successfully updated!" }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@observer.errors, 422), status: 422
      end
    end

    def create
      @observer = Observer.new(observer_params)
      if @observer.save
        render json: { messages: [{ status: 201, title: 'Monitor successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@observer.errors, 422), status: 422
      end
    end

    def destroy
      if @observer.destroy
        render json: { messages: [{ status: 200, title: 'Monitor successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@observer.errors, 422), status: 422
      end
    end

    private

      def set_observer
        @observer = Observer.find(params[:id])
      end

      def observer_params
        set_observer_params = params.require(:observer).permit(:observer_type, :name, :organization,
                                                               :is_active, :logo, :country_id, user_ids: [])
        set_observer_params[:logo] = process_file_base64(set_observer_params[:logo]) if set_observer_params[:logo].present?
        set_observer_params
      end
  end
end
