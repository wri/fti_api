module V1
  class OperatorDocumentResource < JSONAPI::Resource
    caching
    attributes :expire_date, :start_date, :status, :created_at, :updated_at

    has_one :country
    has_one :fmu
    has_one   :operator
    has_one :required_operator_document

    filters :type, :status

    def custom_links(_)
      { self: nil }
    end
  end
end
