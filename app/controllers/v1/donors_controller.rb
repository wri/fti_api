# frozen_string_literal: true

module V1
  class DonorsController < ApiController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Partner'
  end
end