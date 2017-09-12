module V1
  class ObservationDocumentResource < JSONAPI::Resource
    caching

    attributes :name, :attachment, :created_at, :updated_at

    has_one :observation
    has_one :user

    def custom_links(_)
      { self: nil }
    end
  end
end
