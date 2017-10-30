module V1
  class CountryResource < JSONAPI::Resource
    caching

    attributes :iso, :region_iso, :country_centroid,
               :region_centroid, :is_active, :region_name, :name

    has_many :fmus
    has_many :required_operator_documents
    has_many :governments

    filter :iso
    filter :is_active, default: true

    filter :is_active, apply: ->(records, value, _options) {
      case value.first
        when 'true'
          records.where(is_active: true)
        when 'false'
          records.where(is_active: false)
        else
          records
      end
    }


    def custom_links(_)
      { self: nil }
    end
  end
end
