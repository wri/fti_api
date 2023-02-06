# frozen_string_literal: true

module V1
  class OperatorDocumentFmuHistoryResource < OperatorDocumentHistoryResource
    has_one :required_operator_document_fmu
  end
end
