module V1
  class DocumentResource < JSONAPI::Resource
    caching

    attributes :name, :document_type, :user_id, :attachment, :operator_document

    has_one :attacheable, polymorphic: true

    def custom_links(_)
      { self: nil }
    end
  end
end
