module V1
  class ObservationResource < JSONAPI::Resource
    caching

    attributes :observation_type, :publication_date,
               :pv, :is_active, :details, :evidence, :concern_opinion,
               :litigation_status, :lat, :lng,
               :country_id, :fmu_id,
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

    filters :id, :observation_type, :fmu_id, :country_id, :fmu_id,
            :publication_date, :observer_id, :subcategory_id, :years

    filter :category_id, apply: ->(records, value, _options) {
      records.joins(:subcategory).where('subcategories.category_id = ?', value[0].to_i)
    }

    filter :severity_level, apply: ->(records, value, _options) {
      records.joins(:subcategory).where('subcategories.category_id = ?', value[0].to_i)
    }

    filter :years, apply:->(records, value, _options) {
      records.where("extract(year from observations.publication_date) in (#{value.map{|x| x.to_i rescue nil}.join(', ')})")
    }

    def self.sortable_fields(context)
      super + [:'country.iso']
    end

    def custom_links(_)
      { self: nil }
    end
  end
end
