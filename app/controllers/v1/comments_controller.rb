# frozen_string_literal: true

module V1
  class CommentsController < ApplicationController
    include ErrorSerializer

    load_and_authorize_resource class: 'Comment'

    before_action :set_comment, only: :destroy

    def create
      @comment = Comment.build(comment_params)
      if @comment.save
        render json: { messages: [{ status: 201, title: 'Comment successfully created!' }] }, status: 201
      else
        render json: ErrorSerializer.serialize(@comment.errors, 422), status: 422
      end
    end

    def destroy
      if @comment.destroy
        render json: { messages: [{ status: 200, title: 'Comment successfully deleted!' }] }, status: 200
      else
        render json: ErrorSerializer.serialize(@comment.errors, 422), status: 422
      end
    end

    private

      def set_comment
        @comment = Comment.find(params[:id])
      end

      def comment_params
        set_comment_params        = params.require(:comment).permit(:commentable_type, :commentable_id, :body)
        set_comment_params[:user] = @current_user if @current_user.present?

        if set_comment_params[:body].blank? || set_comment_params[:commentable_type].blank? || set_comment_params[:commentable_id].blank?
          render json: { errors: [{ status: 422, title: 'Please review Your comment body params. Params for body, commentable_type and commentable_id must be present!' }] }, status: 422
        end
        set_comment_params
      end
  end
end
