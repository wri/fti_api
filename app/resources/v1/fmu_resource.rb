module V1
  class FmuResource < JSONAPI::Resource
    caching

    attributes :name, :geojson, :certification_fsc, :certification_pefc, :certification_olb

    has_one :country
    has_one :operator

    def custom_links(_)
      { self: nil }
    end

    filter :certification, apply: ->(records, value, _options) {
      records = records.with_certification_fsc       if value.include?('fsc')
      records = records.with_certification_pefc      if value.include?('pefc')
      records = records.with_certification_olb       if value.include?('olb')

      records
    }
  end
end
