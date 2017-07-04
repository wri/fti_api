module V1
  class CountryResource < JSONAPI::Resource
    attributes :iso, :region_iso, :country_centroid, :region_centroid, :is_active, :name, :region_name

    has_many :fmus
  end
end
