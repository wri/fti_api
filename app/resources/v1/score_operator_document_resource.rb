# frozen_string_literal: true

module V1
  class ScoreOperatorDocumentResource < JSONAPI::Resource
    include CacheableByLocale
    caching
    immutable

    has_one :operator

    filters :operator, :date

    attributes :date, :all, :country, :fmu

    filter :date, apply: ->(records, value, _options) {
      records.where('date < ?', value).limit(1)
    }
    
    def self.default_sort
      [{field: 'date', direction: :desc}, {field: 'id', direction: :desc}]
    end

    def custom_links(_)
      { self: nil }
    end
  end
end
