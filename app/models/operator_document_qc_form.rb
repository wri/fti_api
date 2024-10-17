class OperatorDocumentQCForm
  include ActiveModel::Model

  DECISIONS = %w[doc_valid doc_invalid].freeze

  attr_accessor :decision, :admin_comment, :operator_document

  validates :decision, presence: true, inclusion: {in: DECISIONS, allow_blank: true}
  validates :admin_comment, presence: true, if: -> { decision == "doc_invalid" }
  validate :validate_document_is_pending
  validate :validate_document_model

  def initialize(operator_document, attributes = {})
    @operator_document = operator_document
    super(attributes)
  end

  def self.decisions
    DECISIONS.map { |decision| [I18n.t("operator_documents.qc_form.decisions.#{decision}"), decision] }
  end

  def call
    return false if invalid?

    operator_document.update(status: status, admin_comment: admin_comment)
  end

  private

  def validate_document_is_pending
    errors.add(:operator_document, :not_pending_state) unless operator_document.doc_pending?
  end

  def validate_document_model
    promote_errors(operator_document.errors) unless operator_document.valid?
  end

  def status
    return "doc_not_required" if decision == "doc_valid" && operator_document.reason.present?

    decision
  end

  def promote_errors(model_errors)
    model_errors.each do |error|
      errors.import(error)
    end
  end
end
