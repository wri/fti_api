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
#

class OperatorDocument < ApplicationRecord
  belongs_to :operator
  belongs_to :required_operator_document

  has_many :documents, as: :attacheable
  accepts_nested_attributes_for :documents

  after_save :update_operator_percentages, if: :status_changed?

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4 }

  def update_operator_percentages
    operator.update_valid_documents_percentages
  end
end
