# frozen_string_literal: true

module V1
  class OperatorDocumentCountryResource < OperatorDocumentResource
    has_one :required_operator_document_country

    def fetchable_fields
      super - [:fmu_id]
    end

    def self.updatable_fields(context)
      super - [:fmu_id]
    end

    def self.creatable_fields(context)
      super - [:fmu_id]
    end

    delegate :type, to: :@model
  end
end
