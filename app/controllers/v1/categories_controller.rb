# frozen_string_literal: true

module V1
  class CategoriesController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Category'

  end
end
