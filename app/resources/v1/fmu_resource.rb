module V1
  class FmuResource < JSONAPI::Resource
    caching

    attributes :name, :geojson, :certification_fsc, :certification_pefc, :certification_olb

    has_one :country
    has_one :operator

    def custom_links(_)
      { self: nil }
    end

    def fetchable_fields
      if (context[:app] != 'observations-tool')
        super - [:geojson]
      else
        super
      end
    end

  end
end
