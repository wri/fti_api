# frozen_string_literal: true

module V1
  class OperatorsController < ApiController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Operator'

    def show
      puts "<<<<<< #{context[:app]}"
      Rails.logger.error "<<<<<< #{context[:app]}"
      super
    end

  end
end
