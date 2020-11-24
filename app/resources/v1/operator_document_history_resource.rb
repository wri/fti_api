# frozen_string_literal: true

module V1
  class OperatorDocumentHistoryResource < JSONAPI::Resource
    include CacheableByLocale
    include CacheableByCurrentUser
    include OperatorDocumentable
    caching
    immutable

    filter :date

    # The filter doesn't do anything. This is already implemented under the "records" method
    filter :date, apply: ->(records, value, _options) {
      records
    }

    def status
      return @model.status if can_see_document?

      hidden_document_status
    end

    # TODO
    def self.records(options = {})
      context = options[:context]
      operator = context.dig(:filters, 'operator-id')
      date = context.dig(:filters, 'date').to_date

      OperatorDocumentHistory.from_operator_at_date(operator, date)
    rescue StandardError
      return OperatorDocumentHistory.where('true = false') unless operator && date
    end
  end
end
