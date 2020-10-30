# frozen_string_literal: true

module V1
  class OperatorDocumentHistoryResource < JSONAPI::Resource
    include CacheableByLocale
    include CacheableByCurrentUser
    include OperatorDocumentable
    caching
    immutable

    # TODO
    def self.records(options = {})
      context = options[:context]
      user = context[:current_user]
      operator = user&.operator
      return OperatorDocumentHistory.where('true = false') unless operator

      date = "AND updated_at < '2017-10-06'"
      # date = ''
      query = <<~SQL
        (select * from
        (select row_number() over (partition by required_operator_document_id, fmu_id order by created_at asc), *
        from operator_document_histories
        where operator_id = #{operator.id} #{date}) as sq
        where sq.row_number = 1) as operator_document_histories
      SQL

      OperatorDocumentHistory.from(query)
    end
  end
end
