module V1
  class RequiredOperatorDocumentGroupResource < JSONAPI::Resource
    caching
    attributes :name

    has_many :required_operator_documents

    filter :name

    def custom_links(_)
      { self: nil }
    end
  end
end
