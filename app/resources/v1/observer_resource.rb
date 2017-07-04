module V1
  class ObserverResource < JSONAPI::Resource
    attributes :observer_type, :name, :organization, :is_active, :logo

    has_one :country
    has_many   :users
  end
end
