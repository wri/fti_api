module V1
  class RequiredOperatorDocumentResource < JSONAPI::Resource
    #model_hint model: RequiredOperatorDocumentCountry, resource: :required_operator_document
    #model_hint model: RequiredOperatorDocumentFmu, resource: :required_operator_document
    caching
    attributes :name #,:type

    has_one :country
    has_one :required_operator_document_group
    has_many :operator_documents

    filters :name, :type

    def custom_links(_)
      { self: nil }
    end
  end
end
