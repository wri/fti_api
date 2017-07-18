module V1
  class OperatorDocumentResource < JSONAPI::Resource
    caching

    #model_hint model: OperatorDocumentCountry, resource: :operator_document
    #model_hint model: OperatorDocumentFmu, resource: :operator_document
    attributes :expire_date, :start_date, :status, :created_at, :updated_at#, :type

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
