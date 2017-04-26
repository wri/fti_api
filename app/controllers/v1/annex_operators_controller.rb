# frozen_string_literal: true

module V1
  class AnnexOperatorsController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'AnnexOperator'

    before_action :set_annex_operator, only: [:show, :update, :destroy]

    def index
      @annex_operators = AnnexOperatorsIndex.new(self)
      render json: @annex_operators.annex_operators, each_serializer: AnnexOperatorSerializer, links: @annex_operators.links
    end

    def show
      render json: @annex_operator, serializer: AnnexOperatorSerializer, include: [:severities, :categories, :laws, :comments, :country],
             meta: { updated_at: @annex_operator.updated_at, created_at: @annex_operator.created_at }
    end

    def update
      if @annex_operator.update(annex_operator_params)
        render json: { messages: [{ status: 200, title: "Annex Operator successfully updated!" }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@annex_operator.errors, 422), status: 422
      end
    end

    def create
      @annex_operator = AnnexOperator.new(annex_operator_params)
      if @annex_operator.save
        render json: { messages: [{ status: 201, title: 'Annex Operator successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@annex_operator.errors, 422), status: 422
      end
    end

    def destroy
      if @annex_operator.destroy
        render json: { messages: [{ status: 200, title: 'Annex Operator successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@annex_operator.errors, 422), status: 422
      end
    end

    private

      def set_annex_operator
        @annex_operator = AnnexOperator.find(params[:id])
      end

      def annex_operator_params
        params.require(:annex_operator).permit(:country_id, :illegality, :details,
                                               { category_ids: [] }, { law_ids: [] },
                                               { severities_attributes: [:id, :level, :details, :_destroy] })
      end
  end
end
