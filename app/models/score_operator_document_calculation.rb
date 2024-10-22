# frozen_string_literal: true

class ScoreOperatorDocumentCalculation
  attr_reader :docs, :signed_publication_authorization

  def initialize(docs)
    @docs = docs.non_signature
    @signed_publication_authorization = docs.signature.approved.any?
  end

  def apply_to(score_operator_document)
    score_operator_document.all = all
    score_operator_document.fmu = fmu
    score_operator_document.country = country
    score_operator_document.total = total
    score_operator_document.summary_private = summary_private
    score_operator_document.summary_public = summary_public
    score_operator_document
  end

  def all
    divide public_docs(docs.doc_valid).count, total - public_docs(docs.doc_not_required).count
  end

  def fmu
    divide public_docs(fmu_docs.doc_valid).count, fmu_docs.count - public_docs(fmu_docs.doc_not_required).count
  end

  def country
    divide public_docs(country_docs.doc_valid).count, country_docs.count - public_docs(country_docs.doc_not_required).count
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

  def public_docs(docs)
    return docs if signed_publication_authorization

    docs.available
  end

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
    public_docs = signed_publication_authorization ? docs : docs.available
    non_public_docs = docs - public_docs

    non_visible_document_number = public_docs.doc_not_provided.count +
      public_docs.doc_pending.count + public_docs.doc_invalid.count + non_public_docs.count
    {
      doc_not_provided: non_visible_document_number,
      doc_valid: public_docs.doc_valid.count,
      doc_expired: public_docs.doc_expired.count,
      doc_not_required: public_docs.doc_not_required.count
    }
  end
end
