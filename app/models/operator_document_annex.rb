# frozen_string_literal: true

# == Schema Information
#
# Table name: operator_document_annexes
#
#  id                  :integer          not null, primary key
#  name                :string
#  start_date          :date
#  expire_date         :date
#  deleted_at          :date
#  status              :integer
#  attachment          :string
#  uploaded_by         :integer
#  user_id             :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  public              :boolean          default(TRUE), not null
#  invalidation_reason :text
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

  skip_callback :commit, :after, :remove_attachment!
  after_real_destroy :remove_attachment!

  before_validation(on: :create) do
    self.status = OperatorDocumentAnnex.statuses[:doc_pending]
  end
  before_validation :clear_invalidation_reason, if: :doc_valid?

  after_commit :notify_about_changes, if: -> { saved_change_to_status? }

  validates :name, :start_date, :status, presence: true
  validates :invalidation_reason, presence: {if: :doc_invalid?}

  enum :status, {doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4}
  enum :uploaded_by, {operator: 1, monitor: 2, admin: 3, other: 4}

  scope :valid, -> { where(status: OperatorDocumentAnnex.statuses[:doc_valid]) }
  scope :from_operator, ->(operator_ids) {
    where(id: AnnexDocument.where(documentable: OperatorDocument.where(operator_id: operator_ids))
      .or(AnnexDocument.where(documentable: OperatorDocumentHistory.where(operator_id: operator_ids)))
      .select(:operator_document_annex_id))
  }
  scope :orphaned, -> { where.not(id: AnnexDocument.select(:operator_document_annex_id)) }
  scope :history_annexes, -> {
    where(id: AnnexDocument.where(documentable_type: "OperatorDocumentHistory").select(:operator_document_annex_id))
      .where.not(id: AnnexDocument.where(documentable_type: "OperatorDocument").select(:operator_document_annex_id))
  }

  def rejectable?
    !deleted? && (doc_pending? || doc_valid?)
  end

  def approvable?
    !deleted? && (doc_pending? || doc_invalid?)
  end

  def needs_authorization_before_downloading?
    return false if (doc_valid? || doc_expired?) && any_operator_document_without_authorization?

    true
  end

  def operator
    operator_document&.operator || operator_document_histories.first&.operator
  end

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

  private

  def any_operator_document_without_authorization?
    [operator_document, *operator_document_histories].compact.any? { !it.needs_authorization_before_downloading? }
  end

  def clear_invalidation_reason
    self.invalidation_reason = nil
  end

  def notify_about_changes
    return unless operator.present?

    notify_users(operator.all_users, "document_valid") if doc_valid?
    notify_users(operator.all_users, "document_invalid") if doc_invalid?
    notify_users(operator.responsible_admins, "admin_document_pending") if doc_pending?
  end

  def notify_users(users, mail_template)
    users.filter_actives.where.not(email: [nil, ""]).find_each do |user|
      I18n.with_locale(user.locale.presence || I18n.default_locale) do
        OperatorDocumentAnnexMailer.send(mail_template, self, user).deliver_later
      end
    end
  end
end
