# frozen_string_literal: true

module V1
  class OperatorDocumentFmuResource < OperatorDocumentResource
    has_one :required_operator_document_fmu

    delegate :type, to: :@model
  end
end
