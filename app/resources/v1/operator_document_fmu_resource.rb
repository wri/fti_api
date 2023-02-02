# frozen_string_literal: true

module V1
  class OperatorDocumentFmuResource < OperatorDocumentResource
    has_one :required_operator_document_fmu

    def type
      @model.type
    end
  end
end
