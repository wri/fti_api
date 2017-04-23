# frozen_string_literal: true

module V1
  class OperatorsController < ApplicationController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Operator'

    before_action :set_operator, only: [:show, :update, :destroy]

    def index
      @operators = OperatorsIndex.new(self)
      render json: @operators.operators, each_serializer: OperatorSerializer, links: @operators.links
    end

    def show
      render json: @operator, serializer: OperatorSerializer, include: [:country, :users],
             meta: { updated_at: @operator.updated_at, created_at: @operator.created_at }
    end

    def update
      if @operator.update(operator_params)
        render json: { messages: [{ status: 200, title: "Operator successfully updated!" }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@operator.errors, 422), status: 422
      end
    end

    def create
      @operator = Operator.new(operator_params)
      if @operator.save
        render json: { messages: [{ status: 201, title: 'Operator successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@operator.errors, 422), status: 422
      end
    end

    def destroy
      if @operator.destroy
        render json: { messages: [{ status: 200, title: 'Operator successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@operator.errors, 422), status: 422
      end
    end

    private

      def set_operator
        @operator = Operator.find(params[:id])
      end

      def operator_params
        set_operator_params = params.require(:operator).permit(:name, :operator_type, :logo, :concession,
                                                               :is_active, :details, :country_id, user_ids: [])
        set_operator_params[:logo] = process_file_base64(set_operator_params[:logo]) if set_operator_params[:logo].present?
        set_operator_params
      end
  end
end
