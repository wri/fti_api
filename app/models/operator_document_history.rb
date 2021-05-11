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
  acts_as_paranoid

  belongs_to :operator, optional: false
  belongs_to :required_operator_document, -> { with_archived }, required: true
  belongs_to :fmu , -> { with_deleted },  optional: true
  belongs_to :user, optional: true
  belongs_to :document_file, optional: :true
  belongs_to :operator_document, -> { with_deleted }
  has_many :annex_documents, as: :documentable
  has_many :operator_document_annexes, through: :annex_documents

  scope :non_signature, -> { joins(:required_operator_document).where(required_operator_documents: { contract_signature: false }) } # non signature
  scope :valid, -> { joins(:operator_document).where(operator_documents: { status: OperatorDocument.statuses[:doc_valid] }) } # valid doc

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5 }
  enum uploaded_by: { operator: 1, monitor: 2, admin: 3, other: 4 }
  enum source: { company: 1, forest_atlas: 2, other_source: 3 }

  # Returns the collection of OperatorDocumentHistory for a given operator at a point in time
  #
  # @param String operator_id The operator id
  # @param String date the date at which to fetch the state
  def self.from_operator_at_date(operator_id, date)
    # .INFO.
    # The reason why we're adding a day to the date, is that when comparing datetime fields with a date,
    # the datetime will will always be bigger. For example '2020-01-01 02:00:00' > '2020-01-01'
    # We could use a sql function to extract the day, but this approach is more performant
    db_date = (date.to_date + 1.day).to_s(:db)

    # TODO check why for Pete's sake do we have OperatorDocumentHistory with operator_document_id nil?!?!?!
    all_document_histories= OperatorDocumentHistory.where(operator_id: operator_id).where.not(operator_document_id: nil).where('operator_document_histories.updated_at <= ?', db_date).non_signature
    all_operator_document_ids = all_document_histories.pluck(:operator_document_id).uniq

    those_that_i_dont_want =  []
    
    # Removes older OperatorDocumentHistory for the same operator_document_id because we only want the latest one
    all_operator_document_ids.each do |operator_document_id|
      all_for_this_doc = all_document_histories.where(operator_document_id: operator_document_id).order({ updated_at: :asc })
      if all_for_this_doc.count > 1 then those_that_i_dont_want.push(all_for_this_doc[1..-1].pluck(:id)) end
    end

    # Removes OperatorDocumentHistory where operator_document_id has no record in operator_documents because bugs happens
    all_document_histories.each do |odh|
      unless OperatorDocument.exists?(odh.operator_document_id)
        all_document_histories.delete(odh)
      end
    end

    all_document_histories= OperatorDocumentHistory.where.not(id: those_that_i_dont_want.flatten).where(operator_id: operator_id).where.not(operator_document_id: nil).where('operator_document_histories.updated_at <= ?', db_date).non_signature
  end
end