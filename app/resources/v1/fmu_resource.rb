module V1
  class FmuResource < JSONAPI::Resource
    caching

    attributes :name, :geojson, :certification_fsc, :certification_pefc, :certification_olb

    has_one :country
    has_one :operator

    def custom_links(_)
      { self: nil }
    end
  end
end
