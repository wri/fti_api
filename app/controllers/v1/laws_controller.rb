# frozen_string_literal: true

module V1
  class LawsController < ApiController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Law'

  end
end
