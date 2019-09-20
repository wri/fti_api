# frozen_string_literal: true

module V1
  class RequiredGovDocumentResource < JSONAPI::Resource
    caching
    attributes :name, :valid_period, :explanation

    has_one :country
    has_one :required_gov_document_group
    has_many :gov_documents


    filters :name, :document_type

    def custom_links(_)
      { self: nil }
    end
  end
end
