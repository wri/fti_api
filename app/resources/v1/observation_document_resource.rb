module V1
  class ObservationDocumentResource < JSONAPI::Resource
    caching

    attributes :name, :document_type, :user_id, :attachment, :operator_document, :created_at

    has_one :observation

    def custom_links(_)
      { self: nil }
    end
  end
end
