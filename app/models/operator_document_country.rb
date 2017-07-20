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

class OperatorDocumentCountry < OperatorDocument
  belongs_to :required_operator_document_country, foreign_key: 'required_operator_document_id'
end
