# frozen_string_literal: true

class ScoreOperatorPresenter
  attr_reader :docs

  def initialize(docs)
    @docs = docs
  end

  def all
    divide docs.doc_valid.count, total - docs.doc_not_required.count
  end

  def fmu
    divide fmu_docs.doc_valid.count, fmu_docs.count - fmu_docs.doc_not_required.count
  end

  def country
    divide country_docs.doc_valid.count, country_docs.count - country_docs.doc_not_required.count
  end

  def total
    docs.count
  end

  def summary_public
    @summary_public ||= create_summary_public
  end

  def summary_private
    @summary_private ||= create_summary_private
  end

  private

  def divide(numerator, denominator)
    return 0 if denominator.to_f.zero?

    numerator.to_f / denominator.to_f
  end

  def fmu_docs
    docs.fmu_type
  end

  def country_docs
    docs.country_type
  end

  # Creates a json with the attributes and values for all the documents on an operator
  # This information should only be shown to the own authenticated operator
  # @return [Hash]
  def create_summary_private
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
