module V1
  class CountryResource < JSONAPI::Resource
    caching

    attributes :iso, :region_iso, :country_centroid,
               :region_centroid, :is_active, :region_name, :name

    has_many :fmus

    filter :iso
    filter :is_active, default: true

    def custom_links(_)
      { self: nil }
    end
  end
end
