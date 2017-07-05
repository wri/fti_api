module V1
  class ObserverResource < JSONAPI::Resource
    caching
    attributes :observer_type, :name, :organization, :is_active, :logo

    has_one :country
    has_many   :users

    def custom_links(_)
      { self: nil }
    end
  end
end
