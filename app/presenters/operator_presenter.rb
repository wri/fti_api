# frozen_string_literal: true

class OperatorPresenter
  def initialize(operator)
    @operator = operator
  end

  def summary_public
    @summary_public ||= create_summary_public
  end

  def summary_private
    @summary_private ||= create_summary_private
  end

  private

  # Creates a json with the attributes and values for all the documents on an operator
  # This information should only be shown to the own authenticated operator
  # @return [Hash]
  def create_summary_private
    docs = @operator.operator_documents
    {
        doc_not_provided: docs.doc_not_provided.count,
        doc_pending: docs.doc_pending.count,
        doc_invalid: docs.doc_invalid.count,
        doc_valid: docs.doc_valid.non_signature.count,
        doc_expired: docs.doc_expired.count,
        doc_not_required: docs.doc_not_required.count
    }
  end

  # Creates a json with the attributes and values for public documents on an operator
  # This information can be shown to everyone.
  # The documents in the states `doc_not_provided`, `doc_pending` and `doc_invalid` will be summed together
  # @return [Hash]
  def create_summary_public
    docs = @operator.operator_documents
    non_visible_document_number = docs.doc_not_provided.count +
        docs.doc_pending.count + docs.doc_invalid.count
        # what should we do with doc_valid but yes_signature?
    {
        doc_not_provided: non_visible_document_number,
        doc_valid: docs.doc_valid.non_signature.count,
        doc_expired: docs.doc_expired.count,
        doc_not_required: docs.doc_not_required.count
    }
  end
end
