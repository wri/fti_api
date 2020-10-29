# frozen_string_literal: true

module V1
  class OperatorDocumentCountryHistoryResource < OperatorDocumentHistoryResource
    has_one :required_operator_document_country
    has_many :documents

    def fetchable_fields
      super - [:fmu_id]
    end
  end
end
