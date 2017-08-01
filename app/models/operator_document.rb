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
#

class OperatorDocument < ApplicationRecord
  acts_as_paranoid

  belongs_to :operator, required: true
  belongs_to :required_operator_document, required: true

  mount_base64_uploader :attachment, OperatorDocumentUploader

  before_validation :set_expire_date, unless: :expire_date_changed?
  validates_presence_of :start_date
  validates_presence_of :expire_date
  before_save :update_current, if: :current_changed?
  after_save :update_operator_percentages, if: :status_changed?
  before_destroy :insure_unity

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4 }

  def update_operator_percentages
    operator.update_valid_documents_percentages
  end

  def set_expire_date
    self.expire_date = start_date + required_operator_document.valid_period.days rescue start_date
  end

  def update_current
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

  scope :default, ->{
    where(current: true)
  }

  private

  def insure_unity
    if self.attachment.present?
      od = OperatorDocument.new(fmu_id: self.fmu_id, operator_id: self.operator_id,
                                    required_operator_document_id: self.required_operator_document_id,
                                    status: OperatorDocument.statuses[:doc_not_provided])
      od.save!(validate: false)
    else
      false
    end
  end
end
