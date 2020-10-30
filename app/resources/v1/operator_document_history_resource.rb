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

    # TODO
    def self.records(options = {})
      context = options[:context]
      operator = context.dig(:filters, 'operator-id')
      date = context.dig(:filters, 'date')
      return OperatorDocumentHistory.where('true = false') unless operator && date

      query = <<~SQL
        (select * from
        (select row_number() over (partition by required_operator_document_id, fmu_id order by created_at asc), *
        from operator_document_histories
        where operator_id = #{operator} AND updated_at < '#{date}') as sq
        where sq.row_number = 1) as operator_document_histories
      SQL

      OperatorDocumentHistory.from(query)
    end
  end
end
