# frozen_string_literal: true

module V1
  class OperatorsController < ApiController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate, only: [:index, :show, :create]
    load_and_authorize_resource class: 'Operator'

  end
end
