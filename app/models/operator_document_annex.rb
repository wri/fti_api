# frozen_string_literal: true

# == Schema Information
#
# Table name: operator_document_annexes
#
#  id          :integer          not null, primary key
#  name        :string
#  start_date  :date
#  expire_date :date
#  deleted_at  :date
#  status      :integer
#  attachment  :string
#  uploaded_by :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  public      :boolean          default(TRUE), not null
#

class OperatorDocumentAnnex < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  mount_base64_uploader :attachment, OperatorDocumentAnnexUploader

  belongs_to :user, optional: true # FIX db data to eliminate this
  has_many :annex_documents, inverse_of: :operator_document_annex
  has_one :annex_document, -> { where(documentable_type: "OperatorDocument") }, inverse_of: :operator_document_annex
  has_one :operator_document, through: :annex_document, required: false, source: :documentable, source_type: "OperatorDocument"
  has_many :annex_documents_history, -> { where(documentable_type: "OperatorDocumentHistory") },
    class_name: "AnnexDocument", inverse_of: :operator_document_annex
  has_many :operator_document_histories, through: :annex_documents_history, source: :documentable, source_type: "OperatorDocumentHistory"

  before_validation(on: :create) do
    self.status = OperatorDocumentAnnex.statuses[:doc_pending]
  end

  validates :name, :start_date, :status, presence: true

  enum :status, {doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4}
  enum :uploaded_by, {operator: 1, monitor: 2, admin: 3, other: 4}

  scope :valid, -> { where(status: OperatorDocumentAnnex.statuses[:doc_valid]) }
  scope :from_operator, ->(operator_id) { joins(:operator_document).where(operator_documents: {operator_id: operator_id}) }
  scope :orphaned, -> { where.not(id: AnnexDocument.select(:operator_document_annex_id)) }

  def self.expire_document_annexes
    today = Time.zone.today
    documents_to_expire =
      OperatorDocumentAnnex.where("expire_date IS NOT NULL and expire_date < :today::date and status = 3", {today: today})
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} document annexes"
  end

  def operator_document_name
    operator_document&.required_operator_document&.name
  end

  def expire_document_annex
    update(status: OperatorDocumentAnnex.statuses[:doc_expired])
  end
end
