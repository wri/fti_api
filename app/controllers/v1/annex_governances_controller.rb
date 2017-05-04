# frozen_string_literal: true

module V1
  class AnnexGovernancesController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'AnnexGovernance'

    before_action :set_annex_governance, only: [:show, :update, :destroy]

    def index
      @annex_governances = AnnexGovernancesIndex.new(self)
      render json: @annex_governances.annex_governances, each_serializer: AnnexGovernanceSerializer, include: [:severities, :categories, :comments],
             meta: { total_items: @annex_governances.total_items }, links: @annex_governances.links
    end

    def show
      render json: @annex_governance, serializer: AnnexGovernanceSerializer, include: [:severities, :categories, :comments],
             meta: { updated_at: @annex_governance.updated_at, created_at: @annex_governance.created_at }
    end

    def update
      if @annex_governance.update(annex_governance_params)
        render json: { messages: [{ status: 200, title: "Annex Governance successfully updated!" }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@annex_governance.errors, 422), status: 422
      end
    end

    def create
      @annex_governance = AnnexGovernance.new(annex_governance_params)
      if @annex_governance.save
        render json: { messages: [{ status: 201, title: 'Annex Governance successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@annex_governance.errors, 422), status: 422
      end
    end

    def destroy
      if @annex_governance.destroy
        render json: { messages: [{ status: 200, title: 'Annex Governance successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@annex_governance.errors, 422), status: 422
      end
    end

    private

      def set_annex_governance
        @annex_governance = AnnexGovernance.find(params[:id])
      end

      def annex_governance_params
        params.require(:annex_governance).permit(:governance_pillar, :governance_problem, :details,
                                                 { category_ids: [] },
                                                 { severities_attributes: [:id, :level, :details, :_destroy] })
      end
  end
end
