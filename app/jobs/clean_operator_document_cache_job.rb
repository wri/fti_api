class CleanOperatorDocumentCacheJob < ApplicationJob
  queue_as :default

  def perform(operator_id)
    operator = Operator.find_by(id: operator_id)
    return unless operator

    document_ids = operator.operator_document_ids
    history_ids = operator.operator_document_history_ids

    Rails.cache.delete_matched(/operator_documents\/(#{document_ids.join("|")})\//) if document_ids.any?
    Rails.cache.delete_matched(/operator_document_histories\/(#{history_ids.join("|")})\//) if history_ids.any?
  end
end
