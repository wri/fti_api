# frozen_string_literal: true

module V1
  class ObservationsController < ApplicationController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Observation'

    before_action :set_observation, only: [:show, :update, :destroy]

    def index
      @observations = ObservationsIndex.new(self)
      render json: @observations.observations, each_serializer: ObservationSerializer, links: @observations.links
    end

    def show
      render json: @observation, serializer: ObservationSerializer, include: [:documents, :photos,
                                                                              :annex_operator, :annex_governance,
                                                                              :country, :species, :observer, :operator,
                                                                              :severity, :comments,
                                                                              :annex_operator, :annex_governance],
             meta: { updated_at: @observation.updated_at, created_at: @observation.created_at }
    end

    def update
      if @observation.update(observation_params)
        render json: { messages: [{ status: 200, title: "Observation successfully updated!" }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@observation.errors, 422), status: 422
      end
    end

    def create
      @observation = Observation.new(observation_params)
      if @observation.save
        render json: { messages: [{ status: 201, title: 'Observation successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@observation.errors, 422), status: 422
      end
    end

    def destroy
      if @observation.destroy
        render json: { messages: [{ status: 200, title: 'Observation successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@observation.errors, 422), status: 422
      end
    end

    private

      def set_observation
        @observation = Observation.find(params[:id])
      end

      def observation_params
        return_params = params.require(:observation).permit(:pv, :operator_opinion, :litigation_status, :observation_type, :id,
                                                            :user_id, :publication_date, :country_id, :annex_operator_id, :annex_governance_id,
                                                            :observer_id, :operator_id, :government_id, :severity_id, :locale,
                                                            :details, :evidence, { photos_attributes: [:id, :name, :attachment, :user_id, :_destroy] },
                                                            { documents_attributes: [:id, :name, :attachment, :user_id, :document_type, :_destroy] }, :species_ids)

        return_params[:user_id] = params[:observation][:user_id] if @current_user.is_active_admin?
        return_params[:user_id] = @current_user.id               if :create && return_params[:user_id].blank?

        if @current_user.is_active_admin?
          return_params[:is_active] = params[:observation][:is_active]
        end

        if return_params[:photos_attributes].present?
          return_params[:photos_attributes].each do |photo_attributes|
            photo_attributes[:attachment] = process_file_base64(photo_attributes[:attachment].to_s) if photo_attributes[:attachment].present?
            if @current_user.is_active_admin?
              photo_attributes[:user_id] = return_params[:user_id] if return_params[:user_id].present?
              photo_attributes[:user_id] = @current_user.id        if return_params[:user_id].blank?
            else
              photo_attributes[:user_id] = @current_user.id
            end
          end
        end

        if return_params[:documents_attributes].present?
          return_params[:documents_attributes].each do |document_attributes|
            document_attributes[:attachment] = process_file_base64(document_attributes[:attachment].to_s) if document_attributes[:attachment].present?
            if @current_user.is_active_admin?
              document_attributes[:user_id] = return_params[:user_id] if return_params[:user_id].present?
              document_attributes[:user_id] = @current_user.id        if return_params[:user_id].blank?
            else
              document_attributes[:user_id] = @current_user.id
            end
          end
        end
        return_params
      end
  end
end
