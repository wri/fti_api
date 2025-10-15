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
class OperatorDocumentHistory < ApplicationRecord
  acts_as_paranoid

  belongs_to :operator
  belongs_to :required_operator_document, -> { with_archived }, inverse_of: false
  belongs_to :fmu, -> { with_deleted }, optional: true, inverse_of: false
  belongs_to :user, optional: true
  belongs_to :document_file, optional: true
  belongs_to :operator_document, -> { with_deleted }, inverse_of: false
  has_many :annex_documents, as: :documentable, inverse_of: :documentable
  has_many :operator_document_annexes, through: :annex_documents

  scope :fmu_type, -> { where(type: "OperatorDocumentFmuHistory") }
  scope :country_type, -> { where(type: "OperatorDocumentCountryHistory") }
  scope :available, -> { where(public: true) }
  scope :approved, -> { where(status: %i[doc_valid doc_not_required]) }
  scope :signature, -> { joins(:required_operator_document).where(required_operator_documents: {contract_signature: true}) }
  scope :non_signature, -> { joins(:required_operator_document).where(required_operator_documents: {contract_signature: false}) } # non signature
  scope :valid, -> { joins(:operator_document).where(operator_documents: {status: OperatorDocument.statuses[:doc_valid]}) } # valid doc

  enum :status, {doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5}
  enum :uploaded_by, {operator: 1, monitor: 2, admin: 3, other: 4}
  enum :source, {company: 1, forest_atlas: 2, other_source: 3}

  def publication_authorization?
    required_operator_document.contract_signature?
  end

  def needs_authorization_before_downloading?
    return true if publication_authorization?
    return false if (doc_valid? || doc_expired?) && (operator.publication_authorization_signed? || public?)

    true
  end

  # Returns the collection of OperatorDocumentHistory for a given operator at a point in time
  #
  # @param String operator_id The operator id
  # @param String date the date at which to fetch the state
  def self.from_operator_at_date(operator_id, date)
    at_date(date).where(operator_id: operator_id)
  end

  def self.at_date(date)
    # .INFO.
    # The reason why we're adding a day to the date, is that when comparing datetime fields with a date,
    # the datetime will will always be bigger. For example '2020-01-01 02:00:00' > '2020-01-01'
    # We could use a sql function to extract the day, but this approach is more performant
    db_date = (date.to_date + 1.day).to_fs(:db)

    query = <<~SQL
      (select * from
        (select row_number() over (partition by operator_id, required_operator_document_id, fmu_id order by operator_document_updated_at desc), *
         from operator_document_histories
         where operator_document_updated_at <= :db_date
        ) as sq
        where sq.row_number = 1
      ) as operator_document_histories
    SQL

    # coupled with default not deleted scope will only return not deleted
    # deleted document history is created when document is destroyed, when country, fmu is unattributed
    # it will not return destroyed documents
    from(ActiveRecord::Base.sanitize_sql([query, {db_date: db_date}]))
  end
end
