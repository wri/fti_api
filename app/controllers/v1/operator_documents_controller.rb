# frozen_string_literal: true

module V1
  class OperatorDocumentsController < ApiController
    before_action :check_params
    skip_before_action :authenticate, only: [:index, :show]
    load_and_authorize_resource class: 'OperatorDocument'

    protected
    
    # Removes operator.country from the include statement.
    # Workaround to bypass the buggy limitations on the current
    # JSONAPI-Resource's version.
    #
    def check_params
      params["include"]&.slice! "operator.country"
    end
  end
end
