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
#  uploaded_by                   :integer          not null
#  user_id                       :integer
#  reason                        :text
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean          default("true"), not null
#  source                        :integer          default("1"), not null
#  source_info                   :string
#

class OperatorDocumentCountry < OperatorDocument
  belongs_to :required_operator_document_country, foreign_key: 'required_operator_document_id'

  after_update :update_operator_approved, if: -> { required_operator_document.contract_signature && current }

  protected

  def update_operator_approved
    Operator.where(id: operator.id).update(approved: approved?) unless operator.approved == approved?
  end

end
