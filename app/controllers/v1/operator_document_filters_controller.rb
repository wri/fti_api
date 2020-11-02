# frozen_string_literal: true

module V1
  class OperatorDocumentFiltersController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate

    def tree
      result = OpDoc::FetchFilterTree.call
      render json: result.tree.to_json
    end
  end
end
