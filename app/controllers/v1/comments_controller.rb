# frozen_string_literal: true

module V1
  class CommentsController < ApplicationController
    include ErrorSerializer

    load_and_authorize_resource class: 'Comment'

  end
end
