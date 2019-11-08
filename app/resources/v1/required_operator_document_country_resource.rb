# frozen_string_literal: true

module V1
  class RequiredOperatorDocumentCountryResource < JSONAPI::Resource
    caching
    attributes :name, :valid_period, :explanation, :forest_type, :contract_signature

    has_one :country
    has_one :required_operator_document_group
    has_many :operator_document_countries

    filters :name, :type

    def custom_links(_)
      { self: nil }
    end
  end
end
