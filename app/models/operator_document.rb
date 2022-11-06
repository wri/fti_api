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

  attr_accessor :skip_score_recalculation

  belongs_to :operator, touch: true
  belongs_to :required_operator_document, -> { with_archived }
  belongs_to :fmu, optional: true
  belongs_to :user, optional: true
  belongs_to :document_file, optional: true, inverse_of: :operator_document

  has_many :annex_documents, as: :documentable, dependent: :destroy, inverse_of: :documentable
  has_many :operator_document_annexes, through: :annex_documents
  has_many :notifications
  accepts_nested_attributes_for :document_file

  before_validation :set_expire_date, unless: :expire_date?

  validates_presence_of :start_date, if: :document_file_id?
  validates_presence_of :expire_date, if: :document_file_id # TODO We set expire_date on before_validation
  validate :reason_or_file

  before_save :set_type, on: %w[create update]
  before_create :set_status
  before_create :delete_previous_pending_document

  after_save :create_history, if: :changed?
  after_save :recalculate_scores, if: :score_related_attribute_changed?
  after_save :remove_notifications, if: :expire_date_changed?

  after_destroy :regenerate
  after_destroy :recalculate_scores

  scope :by_forest_types,                        ->(forest_type_id) { includes(:fmu).where(fmus: { forest_type: forest_type_id }) }
  scope :by_country,                             ->(country_id) { includes(:required_operator_document).where(required_operator_documents: { country_id: country_id }) }
  scope :by_required_operator_document_group,    ->(required_operator_document_group_id) { includes(:required_operator_document).where(required_operator_documents: { required_operator_document_group_id: required_operator_document_group_id }) }
  scope :exclude_by_required_operator_document_group,    ->(required_operator_document_group_id) { includes(:required_operator_document).where.not(required_operator_documents: { required_operator_document_group_id: required_operator_document_group_id }) }
  scope :fmu_type,                               -> { where(type: 'OperatorDocumentFmu') }
  scope :country_type,                           -> { where(type: 'OperatorDocumentCountry') }
  scope :from_active_operators,                  -> { joins(:operator).where(operators: { is_active: true }) }
  scope :approved,                               -> { where(status: %i[doc_valid doc_not_required]) }
  scope :valid,                                  -> { where(status: :doc_valid) }
  scope :required,                               -> { where.not(status: :doc_not_required) }
  scope :from_user,                              ->(operator_id) { where(operator_id: operator_id) }
  scope :by_source,                              ->(source_id) { where(source: source_id) }
  scope :available,                              -> { where(public: true) }
  scope :signature,                              -> {
  joins(:required_operator_document).where(required_operator_documents: { contract_signature: true })
}
  scope :non_signature,                          -> {
  joins(:required_operator_document).where(required_operator_documents: { contract_signature: false })
}                                                  # non signature
  scope :to_expire,                              ->(date) {
  joins(:required_operator_document)
    .where('expire_date < ?', date)
    .where(status: EXPIRABLE_STATUSES)
    .where(required_operator_documents: { contract_signature: false })
}

  enum status: { doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5 }
  enum uploaded_by: { operator: 1, monitor: 2, admin: 3, other: 4 }
  enum source: { company: 1, forest_atlas: 2, other_source: 3 }

  NON_HISTORICAL_ATTRIBUTES = %w[id attachment updated_at created_at].freeze
  EXPIRABLE_STATUSES = statuses.slice(:doc_valid, :doc_expired).values.freeze

  def self.expire_documents
    documents_to_expire = OperatorDocument.to_expire(Date.today)
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} documents"
  end

  def build_history
    mapping = self.attributes.except(*NON_HISTORICAL_ATTRIBUTES)
    mapping['operator_document_id'] = id
    # we will copy object timestamps and keep using Rails timestamps
    # as how they normally are used, to know when history was created
    mapping['operator_document_updated_at'] = updated_at
    mapping['operator_document_created_at'] = created_at
    mapping['type'] += 'History'
    OperatorDocumentHistory.new mapping
  end

  # Creates an OperatorDocumentHistory for the current OperatorDocument
  def create_history
    odh = build_history
    odh.operator_document_annexes = operator_document_annexes
    odh.save!
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

  def recalculate_scores
    return if skip_score_recalculation

    ScoreOperatorDocument.recalculate!(operator)
  end

  def score_related_attribute_changed?
    status_changed? || (!operator.approved? && public_changed?)
  end

  def regenerate
    # It only allows for (soft) deletion of the operator documents when:
    # 1 - The Operator was deleted  (destroyed_by_association)
    # 2 - The Fmu was deleted (destroyed_by_association)
    # 3 - The Required Operator Document was deleted (destroyed_by_association)
    # 4 - The Operator is no longer active for this Fmu

    create_history and return if destroyed_by_association
    create_history and return if fmu_id && (operator_id != fmu.operator&.id)

    update!(
      status: OperatorDocument.statuses[:doc_not_provided],
      expire_date: nil, start_date: Date.today, created_at: DateTime.now, updated_at: DateTime.now,
      deleted_at: nil, uploaded_by: nil, user_id: nil, reason: nil, note: nil, response_date: nil,
      source: nil, source_info: nil, document_file_id: nil
    )
    self.skip_score_recalculation = true
  end

  def set_type
    return if type.present?

    self.type = 'OperatorDocumentFmu' if required_operator_document.is_a?(RequiredOperatorDocumentFmu)
    self.type = 'OperatorDocumentCountry' if required_operator_document.is_a?(RequiredOperatorDocumentCountry)
  end

  # Removes the existing notifications for an operator document
  # as long as the new expire date is longer than the notification period or the group has been removed
  def remove_notifications
    Notification.includes(:notification_group).unsolved.where(operator_document_id: id).each do |notification|
      notification.solve! and next unless notification.notification_group_id
      next if Date.today + notification.notification_group.days > expire_date

      notification.solve!
    end
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
