# frozen_string_literal: true

class ScoreOperatorPresenter
  def initialize(score_operator_document)
    @score_operator_document = score_operator_document
    @docs = OperatorDocumentHistory.from_operator_at_date(@score_operator_document.operator.id, @score_operator_document.date).non_signature
  end

  def all
    @docs.doc_valid.count.to_f / (@docs.count - @docs.doc_not_required.count).to_f
  end

  def total
    @docs.count
  end

  def summary_public
    @summary_public = create_summary_public
  end

  def summary_private
    @summary_private = create_summary_private
  end

  private

  # Creates a json with the attributes and values for all the documents on an operator
  # This information should only be shown to the own authenticated operator
  # @return [Hash]
  def create_summary_private
    docs = @docs
    {
        doc_not_provided: docs.doc_not_provided.count,
        doc_pending: docs.doc_pending.count,
        doc_invalid: docs.doc_invalid.count,
        doc_valid: docs.doc_valid.count,
        doc_expired: docs.doc_expired.count,
        doc_not_required: docs.doc_not_required.count
    }
  end

  # Creates a json with the attributes and values for public documents on an operator
  # This information can be shown to everyone.
  # The documents in the states `doc_not_provided`, `doc_pending` and `doc_invalid` will be summed together
  # @return [Hash]
  def create_summary_public
    docs = @docs
    non_visible_document_number = docs.doc_not_provided.count +
        docs.doc_pending.count + docs.doc_invalid.count
    {
        doc_not_provided: non_visible_document_number,
        doc_valid: docs.doc_valid.count,
        doc_expired: docs.doc_expired.count,
        doc_not_required: docs.doc_not_required.count
    }
  end
end
