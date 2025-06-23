# frozen_string_literal: true

# == Schema Information
#
# Table name: operator_document_histories
#
#  id                            :integer          not null, primary key
#  type                          :string
#  expire_date                   :date
#  start_date                    :date
#  status                        :integer
#  uploaded_by                   :integer
#  reason                        :text
#  response_date                 :datetime
#  public                        :boolean          default(FALSE), not null
#  source                        :integer
#  source_info                   :string
#  fmu_id                        :integer
#  document_file_id              :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  operator_document_id          :integer
#  operator_id                   :integer
#  user_id                       :integer
#  required_operator_document_id :integer
#  deleted_at                    :datetime
#  operator_document_updated_at  :datetime         not null
#  operator_document_created_at  :datetime         not null
#  admin_comment                 :text
#
class OperatorDocumentFmuHistory < OperatorDocumentHistory
end
