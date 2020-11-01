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
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean
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
#
class OperatorDocumentHistory < ApplicationRecord
  belongs_to :operator, optional: false
  belongs_to :required_operator_document, -> { with_archived }, required: true
  belongs_to :fmu, optional: true
  belongs_to :user, optional: true
  belongs_to :document_file, optional: :true
  has_many :annex_documents, as: :documentable
  has_many :operator_document_annexes, through: :annex_documents

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5 }
  enum uploaded_by: { operator: 1, monitor: 2, admin: 3, other: 4 }
  enum source: { company: 1, forest_atlas: 2, other_source: 3 }

  # Returns the operator documents for an operator at a point in time
  # @param String operator_id The operator id
  # @param String date the date at which to fetch the state
  def self.from_operator_at_date(operator_id, date)
    query = <<~SQL
      (select * from
      (select row_number() over (partition by required_operator_document_id, fmu_id order by updated_at desc), *
      from operator_document_histories
      where operator_id = #{operator_id} AND updated_at < '#{date.to_date.to_s(:db)}') as sq
      where sq.row_number = 1) as operator_document_histories
    SQL

    from(query)
  end
end
