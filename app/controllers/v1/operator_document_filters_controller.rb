# frozen_string_literal: true

module V1
  class OperatorDocumentFiltersController < APIController
    include ErrorSerializer

    skip_before_action :authenticate

    def tree
      render json: OperatorDocumentFilterTree.new.to_json
    end
  end
end
