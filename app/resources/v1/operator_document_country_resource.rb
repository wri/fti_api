module V1
  class OperatorDocumentCountryResource < JSONAPI::Resource
    caching
    attributes :type, :expire_date, :start_date, :status, :created_at, :updated_at

    has_one :country
    has_one   :operator
    has_one :required_operator_document_country

    filters :type, :status

    def custom_links(_)
      { self: nil }
    end
  end
end
