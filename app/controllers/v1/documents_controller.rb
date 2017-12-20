# frozen_string_literal: true

module V1
  class DocumentsController < ApiController

    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'Document'

  end
end
