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
#  deleted_at                    :datetime
#  uploaded_by                   :integer
#  user_id                       :integer
#  reason                        :text
#  response_date                 :datetime
#  public                        :boolean          default(TRUE), not null
#  source                        :integer          default("company")
#  source_info                   :string
#  document_file_id              :integer
#  admin_comment                 :text
#

class OperatorDocumentFmu < OperatorDocument
  belongs_to :required_operator_document_fmu, foreign_key: "required_operator_document_id", inverse_of: :operator_document_fmus
  belongs_to :fmu
end
