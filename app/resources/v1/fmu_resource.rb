# frozen_string_literal: true

module V1
  class FmuResource < JSONAPI::Resource
    include CacheableByLocale
    caching
    paginator :none

    attributes :name, :geojson, :forest_type,
               :certification_fsc, :certification_pefc, :certification_olb,
               :certification_pafc, :certification_fsc_cw, :certification_tlv,
               :certification_ls

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
      values = value.select { |c| %w(fsc pefc olb pafc fsc_cw tlv ls).include? c }
      return records unless values.any?

      certifications = []
      values.each do |v|
        certifications << "certification_#{v} = true"
      end

      records = records.where(certifications.join(' OR ')).distinct

      records
    }

    filter :free, apply: ->(records, value, _options) {
      records = records.filter_by_free

      records
    }
  end
end
