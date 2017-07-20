# frozen_string_literal: true

module V1
  class SpeciesController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Species'

    before_action :set_species, only: [:show, :update, :destroy]

  end
end
