# frozen_string_literal: true

# == Schema Information
#
# Table name: operator_document_annexes
#
#  id                   :integer          not null, primary key
#  operator_document_id :integer
#  name                 :string
#  start_date           :date
#  expire_date          :date
#  deleted_at           :date
#  status               :integer
#  attachment           :string
#  uploaded_by          :integer
#  user_id              :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  public               :boolean          default(TRUE), not null
#

class OperatorDocumentAnnex < ApplicationRecord
  acts_as_paranoid

  mount_base64_uploader :attachment, OperatorDocumentAnnexUploader

  belongs_to :operator_document, optional: false
  belongs_to :user

  before_validation(on: :create) do
    self.status = OperatorDocumentAnnex.statuses[:doc_pending]
  end

  validates_presence_of :operator_document_id
  validates_presence_of :start_date
  validates_presence_of :status

  enum status: { doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4 }
  enum uploaded_by: { operator: 1, monitor: 2, admin: 3, other: 4 }

  scope :valid,     ->            { where(status: OperatorDocumentAnnex.statuses[:doc_valid]) }
  scope :from_user, ->(operator_id) { joins(:operator_document).where(operator_documents: { operator_id: operator_id }) }

  def self.expire_document_annexes
    documents_to_expire =
        OperatorDocumentAnnex.where("expire_date IS NOT NULL and expire_date < '#{Date.today}'::date and status = 3")
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} document annexes"
  end

  def expire_document_annex
    self.update(status: OperatorDocumentAnnex.statuses[:doc_expired])
  end
end
