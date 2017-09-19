module V1
  class ObservationDocumentResource < JSONAPI::Resource
    caching

    attributes :name, :attachment, :created_at, :updated_at

    has_one :observation
    has_one :user

    filters :observation_id, :name, :user_id

    def custom_links(_)
      { self: nil }
    end
  end
end
