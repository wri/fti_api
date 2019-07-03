# frozen_string_literal: true

module V1
  class OperatorDocumentCountryResource < OperatorDocumentResource
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :current, :reason

    has_one :required_operator_document_country
    has_many :documents
    has_many :operator_document_annexes

  end
end
