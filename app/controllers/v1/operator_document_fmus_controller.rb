# frozen_string_literal: true

module V1
  class OperatorDocumentFmusController < ApiController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'OperatorDocument'
  end
end
