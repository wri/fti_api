# frozen_string_literal: true

module V1
  class GovDocumentsController < APIController
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'GovDocument'
  end
end
