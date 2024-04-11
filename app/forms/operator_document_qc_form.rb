class OperatorDocumentQCForm
  include ActiveModel::Model

  DECISIONS = %w[doc_valid doc_invalid].freeze

  attr_accessor :decision, :admin_comment, :operator_document

  validates :decision, presence: true, inclusion: {in: DECISIONS, allow_blank: true}
  validates :admin_comment, presence: true, if: -> { decision == "doc_invalid" }
  validate :document_is_pending

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

  def document_is_pending
    errors.add(:operator_document, :not_pending_state) unless operator_document.doc_pending?
  end

  def status
    return "doc_not_required" if decision == "doc_valid" && operator_document.reason.present?

    decision
  end
end
