# frozen_string_literal: true

# == Schema Information
#
# Table name: operator_documents
#
#  id                            :integer          not null, primary key
#  type                          :string
#  expire_date                   :date
#  start_date                    :date
#  fmu_id                        :integer
#  required_operator_document_id :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  status                        :integer
#  operator_id                   :integer
#  attachment                    :string
#  current                       :boolean
#  deleted_at                    :datetime
#  uploaded_by                   :integer
#  user_id                       :integer
#  reason                        :text
#  note                          :text
#  response_date                 :datetime
#

class OperatorDocument < ApplicationRecord
  acts_as_paranoid

  belongs_to :operator, required: true, touch: true
  belongs_to :required_operator_document, required: true
  belongs_to :fmu
  belongs_to :user
  has_many :operator_document_annexes

  mount_base64_uploader :attachment, OperatorDocumentUploader

  before_validation :set_expire_date, unless: :expire_date_changed?

  validates_presence_of :start_date, if: :attachment?
  validates_presence_of :expire_date, if: :attachment?
  validate :reason_or_attachment

  before_save :update_current, on: %w[create update], if: :current_changed?
  before_create :set_status
  before_create :delete_previous_pending_document
  after_save :update_operator_percentages, on: %w[create update],  if: :status_changed?

  before_destroy :insure_unity

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5 }
  enum uploaded_by: { operator: 1, monitor: 2, admin: 3, other: 4 }

  def update_operator_percentages
    operator.update_valid_documents_percentages
  end

  def set_expire_date
    self.expire_date = start_date + required_operator_document.valid_period.days rescue start_date
  end

  def update_current
    return if operator.present? && operator.marked_for_destruction?
    if current == true
      documents_to_update = OperatorDocument.where(fmu_id: self.fmu_id, operator_id: self.operator_id,
                                                   required_operator_document_id: self.required_operator_document_id, current: true)
                                .where.not(id: self.id)
      documents_to_update.find_each {|x| x.update_attributes!(current: false)}
    else
      documents_to_update = OperatorDocument.where(fmu_id: self.fmu_id, operator_id: self.operator_id,
                                                   required_operator_document_id: self.required_operator_document_id, current: true)
      unless documents_to_update.any?
        self.update_attributes(current: false)
      end
    end
  end

  def self.expire_documents
    documents_to_expire = OperatorDocument.where("expire_date < '#{Date.today}'::date and status = 3")
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} documents"
  end

  def expire_document
    self.update_attributes(status: OperatorDocument.statuses[:doc_expired])
  end

  scope :actual,    -> { where(current: true, deleted_at: nil) }
  scope :valid,     -> { actual.where(status: OperatorDocument.statuses[:doc_valid]) }
  scope :required,  -> { actual.where.not(status: OperatorDocument.statuses[:doc_not_required]) }
  scope :from_user, ->(operator_id) { where(operator_id: operator_id) }



  private

  def insure_unity
    return if operator.present? && operator.marked_for_destruction?
    if self.current && self.required_operator_document.present?
      od = OperatorDocument.new(fmu_id: self.fmu_id, operator_id: self.operator_id,
                                required_operator_document_id: self.required_operator_document_id,
                                status: OperatorDocument.statuses[:doc_not_provided], type: self.type,
                                current: true)
      od.save!(validate: false)
    end
  end

  def set_status
    if attachment.present? || reason.present?
      self.status = OperatorDocument.statuses[:doc_pending]
    else
      self.status = OperatorDocument.statuses[:doc_not_provided]
    end
  end

  def delete_previous_pending_document
    pending_documents = OperatorDocument.where(operator_id: self.operator_id,
                                               required_operator_document_id: self.required_operator_document_id,
                                               status: OperatorDocument.statuses[:doc_pending])
    pending_documents.each {|x| x.destroy}
  end

  def reason_or_attachment
    if self.attachment.present? && self.reason.present?
      self.errors[:reason] << 'Cannot have a reason not to have a documen '
    end
  end

end
