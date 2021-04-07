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
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean          default("true"), not null
#  source                        :integer          default("1")
#  source_info                   :string
#  document_file_id              :integer
#

class OperatorDocument < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  belongs_to :operator, optional: false, touch: true
  belongs_to :required_operator_document, -> { with_archived }, required: true
  belongs_to :fmu
  belongs_to :user
  belongs_to :document_file, optional: :true
  has_many :annex_documents, as: :documentable, dependent: :destroy
  has_many :operator_document_annexes, through: :annex_documents
  accepts_nested_attributes_for :document_file

  if attribute_names.include? :attachment
    mount_base64_uploader :attachment, OperatorDocumentUploader # TODO Remove this after migrating
  end

  before_validation :set_expire_date, unless: :expire_date?

  validates_presence_of :start_date, if: :document_file_id?
  validates_presence_of :expire_date, if: :document_file_id # TODO We set expire_date on before_validation
  validate :reason_or_file

  before_save :set_type, on: %w[create update]
  before_create :set_status
  before_create :delete_previous_pending_document
  after_save ->{ ScoreOperatorDocument.recalculate!(operator) }, on: %w[create update],  if: :status_changed?
  after_save :create_history

  after_destroy :regenerate

  scope :fmu_type,      -> { where(type: 'OperatorDocumentFmu') }
  scope :country_type,  -> { where(type: 'OperatorDocumentCountry') }
  scope :by_country,    ->(country_id) { joins(:required_operator_document).where(required_operator_documents: { country_id: country_id }) }
  scope :valid,         -> { where(status: OperatorDocument.statuses[:doc_valid]) }
  scope :required,      -> { where.not(status: OperatorDocument.statuses[:doc_not_required]) }
  scope :from_user,     ->(operator_id) { where(operator_id: operator_id) }
  scope :available,     -> { where(public: true) }
  scope :non_signature, -> { joins(:required_operator_document).where(required_operator_documents: { contract_signature: false }) } # non signature
  scope :to_expire,     ->(date) {
    joins(:required_operator_document)
              .where("expire_date < '#{date}'::date and status = #{OperatorDocument.statuses[:doc_valid]} and required_operator_documents.contract_signature = false") 
  }

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5 }
  enum uploaded_by: { operator: 1, monitor: 2, admin: 3, other: 4 }
  enum source: { company: 1, forest_atlas: 2, other_source: 3 }

  NON_HISTORICAL_ATTRIBUTES = %w[id attachment current].freeze

  def self.expire_documents
    documents_to_expire = OperatorDocument.to_expire(Date.today)
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} documents"
  end

  # Creates an OperatorDocumentHistory for the current OperatorDocument
  def create_history(attrs = {})
    mapping = self.attributes.except *NON_HISTORICAL_ATTRIBUTES
    mapping['operator_document_id'] = self.id
    mapping['type'] += 'History'
    attrs.select! { |x| OperatorDocumentHistory.new.attributes.key?(x) }

    odh = OperatorDocumentHistory.create mapping.merge(attrs)
    return odh unless odh.persisted?

    odh.operator_document_annexes = self.operator_document_annexes
    odh
  end

  def set_expire_date
    self.expire_date = start_date + required_operator_document.valid_period.days rescue start_date
  end

  def expire_document
    self.update(status: OperatorDocument.statuses[:doc_expired])
  end

  # When a doc is valid or not required
  def approved?
    %w(doc_not_required doc_valid).include?(status)
  end

  private

  def regenerate
    # It only allows for (soft) deletion of the operator documents when:
    # 1 - The Operator was deleted
    # 2 - The Fmu was deleted
    # 3 - The Required Operator Document was deleted
    # 4 - The Operator is no longer active for this Fmu

    create_history and return if (operator.present? && operator.marked_for_destruction?) || (required_operator_document.present? && required_operator_document.marked_for_destruction?)
    create_history and return if fmu_id && Fmu.find(fmu_id).present? && Fmu.find(fmu_id).marked_for_destruction?
    create_history and return if fmu_id && (operator_id != fmu.operator&.id)

    update status: OperatorDocument.statuses[:doc_not_provided],
           expire_date: nil, start_date: Date.today, created_at: DateTime.now, updated_at: DateTime.now,
           deleted_at: nil, uploaded_by: nil, user_id: nil, reason: nil, note: nil, response_date: nil,
           source: nil, source_info: nil, document_file_id: nil

    true
  end

  def set_type
    return if type.present?

    self.type = 'OperatorDocumentFmu' if required_operator_document.is_a?(RequiredOperatorDocumentFmu)
    self.type = 'OperatorDocumentCountry' if required_operator_document.is_a?(RequiredOperatorDocumentCountry)
  end

  def set_status
    status =
      if document_file.present? || reason.present?
        :doc_pending
      else
        :doc_not_provided
      end

    self.status = OperatorDocument.statuses[status]
  end

  def delete_previous_pending_document
    pending_documents = OperatorDocument.where(operator_id: self.operator_id,
                                               fmu_id: self.fmu_id,
                                               required_operator_document_id: self.required_operator_document_id,
                                               status: OperatorDocument.statuses[:doc_pending])
    pending_documents.each { |x| x.destroy }
  end

  def reason_or_file
    return if self.document_file.blank? || self.reason.blank?

    self.errors[:reason] << 'Cannot have a reason not to have a document'
  end
end
