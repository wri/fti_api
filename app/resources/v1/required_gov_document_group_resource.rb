# frozen_string_literal: true

module V1
  class RequiredGovDocumentGroupResource < BaseResource
    include CacheableByLocale
    caching
    attributes :name, :position

    has_many :required_gov_documents
    has_one :parent, class_name: "RequiredGovDocumentGroup"

    filter :name

    def self.default_sort
      [{field: "position", direction: :asc}]
    end

    def self.apply_includes(records, directives)
      super.with_translations(I18n.locale)
    end
  end
end
