# frozen_string_literal: true

module V1
  class RequiredOperatorDocumentCountryResource < BaseResource
    include CacheableByLocale
    caching
    attributes :name, :valid_period, :explanation, :forest_types, :contract_signature

    has_one :country
    has_one :required_operator_document_group
    has_many :operator_document_countries

    filters :name, :type
  end
end
