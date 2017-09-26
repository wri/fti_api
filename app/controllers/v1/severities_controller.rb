# frozen_string_literal: true

module V1
  class SeveritiesController < ApiController

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Severity'

  end
end
