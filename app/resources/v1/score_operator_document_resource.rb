# frozen_string_literal: true

module V1
  class ScoreOperatorDocumentResource < BaseResource
    include CacheableByLocale
    include CacheableByCurrentUser
    caching
    immutable

    has_one :operator

    filters :operator, :date

    attributes :date, :all, :country, :fmu, :total, :summary

    filter :date, apply: ->(records, value, _options) {
      records.where('date < ?', value).limit(1)
    }

    def self.default_sort
      [{ field: 'date', direction: :desc }, { field: 'id', direction: :desc }]
    end

    def summary
      can_see_documents? ? @model.summary_private : @model.summary_public
    end

    private

    def can_see_documents?
      user = @context[:current_user]

      return true if user&.user_permission&.user_role =='admin'
      return true if user&.is_operator?(@model.operator_id)

      false
    end
  end
end
