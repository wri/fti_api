# frozen_string_literal: true

module V1
  class FmuResource < JSONAPI::Resource
    include CachableByLocale
    caching
    paginator :none

    attributes :name, :geojson, :forest_type,
               :certification_fsc, :certification_pefc, :certification_olb,
               :certification_vlc, :certification_vlo, :certification_tltv

    has_one :country
    has_one :operator

    filters :country, :free, :certification

    def forest_type
      Fmu::FOREST_TYPES[@model.forest_type.to_sym][:geojson_label] if @model.forest_type
    end

    def custom_links(_)
      { self: nil }
    end

    filter :certification, apply: ->(records, value, _options) {
      records = records.with_certification_fsc       if value.include?('fsc')
      records = records.with_certification_pefc      if value.include?('pefc')
      records = records.with_certification_olb       if value.include?('olb')
      records = records.with_certification_vlc       if value.include?('vlc')
      records = records.with_certification_vlo       if value.include?('vlo')
      records = records.with_certification_tltv      if value.include?('tltv')

      records
    }

    filter :free, apply: ->(records, value, _options) {
      records = records.filter_by_free

      records
    }
  end
end
