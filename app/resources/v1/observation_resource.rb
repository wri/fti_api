module V1
  class ObservationResource < JSONAPI::Resource
    caching

    attributes :observation_type, :publication_date,
               :pv, :is_active, :details, :evidence, :concern_opinion,
               :litigation_status, :lat, :lng,
               :observation_type, :country_id, :fmu_id, :publication_date,
               :observer_id, :subcategory_id, :severity_id

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

    filters :id, :observation_type, :fmu_id, :country_id, :fmu_id, :publication_date, :observer_id, 'subcategory.category_id'

    def custom_links(_)
      { self: nil }
    end
  end
end
