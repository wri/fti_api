# frozen_string_literal: true

module V1
  class OperatorDocumentHistoryResource < BaseResource
    include CacheableByLocale
    include CacheableByCurrentUser
    include OperatorDocumentable
    # removing caching is causing errors, more info here https://github.com/wri/fti_api/issues/284
    # TODO: probably bug in api library
    caching
    immutable

    filter :date

    attributes :operator_document_id

    # The frontend is not sending the page size so we'll remove it here to make sure everything works.
    # Since we are enforcing the operator-id to be sent, there's no risk that this request will overflow
    paginator :none

    # The filter doesn't do anything. This is already implemented under the "records" method
    filter :date, apply: ->(records, value, _options) {
      records
    }

    def updated_at
      return nil unless document_visible?

      @model.operator_document_updated_at
    end

    def created_at
      return nil unless document_visible?

      @model.operator_document_created_at
    end

    def self.records(options = {})
      context = options[:context]
      operator_id = context.dig(:filters, "operator-id")
      date = context.dig(:filters, "date").to_date

      return OperatorDocumentHistory.none unless operator_id && date

      OperatorDocumentHistory.from_operator_at_date(operator_id, date).non_signature
    end
  end
end
