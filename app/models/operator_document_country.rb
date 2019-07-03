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
#  public                        :boolean          default(TRUE), not null
#

class OperatorDocumentCountry < OperatorDocument
  belongs_to :required_operator_document_country, foreign_key: 'required_operator_document_id'
  after_create :invalidate_operator, if: -> { required_operator_document.contract_signature }
  after_destroy :validate_operator,  if: -> { required_operator_document.contract_signature }

  protected

  def invalidate_operator
    Operator.find(operator_id).update(approved: false) if operator.approved
  end

  def validate_operator
    Operator.find(operator_id).update(approved: true) unless operator.approved
  end

  # If there are current documents of contract signature that are not
  # valid or not required, then the operator is not approved
  def update_operator_approved
    approved = required_operator_document.contract_signature
    Operator.update(operator_id: operator.id, approved: approved) unless operator.approved == approved
  end

end
