# frozen_string_literal: true

module V1
  class CountriesController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Country'

    before_action :set_country, only: [:show, :update, :destroy]
  end
end
