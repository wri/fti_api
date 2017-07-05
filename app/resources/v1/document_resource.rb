module V1
  class DocumentResource < JSONAPI::Resource
    caching

    attributes :name, :attachment, :document_type, :user_id

    has_one :attacheable

    def custom_links(_)
      { self: nil }
    end
  end
end
