# frozen_string_literal: true

module V1
  class SpeciesController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Species'
  end
end
