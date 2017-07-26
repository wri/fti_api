# frozen_string_literal: true

module V1
  class GovernmentsController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Government'

    before_action :set_government, only: [:show, :update, :destroy]
  end
end
