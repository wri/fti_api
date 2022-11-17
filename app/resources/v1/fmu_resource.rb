# frozen_string_literal: true

module V1
  class FmuResource < BaseResource
    include CacheableByLocale
    caching
    paginator :none

    attributes :name, :geojson, :forest_type,
               :certification_fsc, :certification_pefc, :certification_olb,
               :certification_pafc, :certification_fsc_cw, :certification_tlv,
               :certification_ls

    has_one :country
    has_one :operator, foreign_key_on: :related

    filters :country, :free, :certification, :operator

    def forest_type
      Fmu::FOREST_TYPES[@model.forest_type.to_sym][:geojson_label] if @model.forest_type
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

    filter :observer_id, apply: ->(records, value, _options) {
      records.where(
        id: Observation.own_with_inactive(value[0].to_i).select(:fmu_id).distinct.pluck(:fmu_id)
      )
    }
  end
end
