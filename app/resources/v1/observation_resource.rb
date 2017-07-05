module V1
  class ObservationResource < JSONAPI::Resource
    caching

    attributes :observation_type, :publication_date,
               :pv, :is_active, :details, :evidence, :concern_opinion, :litigation_status, :lat, :lng

    has_many :species
    has_many :comments
    has_many :photos
    has_many :documents

    has_one :country
    has_one :subcategory
    has_one :severity
    has_one :user
    has_one :observer
    has_one :operator
    has_one :government

    def custom_links(_)
      { self: nil }
    end
  end
end
