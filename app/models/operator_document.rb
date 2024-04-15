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
#  public                        :boolean          default(TRUE), not null
#  source                        :integer          default("company")
#  source_info                   :string
#  document_file_id              :integer
#  admin_comment                 :text
#

class OperatorDocument < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  attr_accessor :skip_score_recalculation

  belongs_to :operator, touch: true
  belongs_to :required_operator_document, -> { with_archived }, inverse_of: :operator_documents
  belongs_to :fmu, optional: true
  belongs_to :user, optional: true
  belongs_to :document_file, optional: true, inverse_of: :operator_document

  has_many :annex_documents, as: :documentable, dependent: :destroy, inverse_of: :documentable
  has_many :operator_document_annexes, through: :annex_documents
  has_many :notifications
  accepts_nested_attributes_for :document_file

  before_validation :set_expire_date, unless: :expire_date?
  before_validation :set_status, on: :create

  validates :start_date, presence: {if: :document_file_id?}
  validates :expire_date, presence: {if: :document_file_id?}
  validates :admin_comment, presence: {if: :doc_invalid?}
  validate :reason_or_file

  before_save :set_type
  before_create :delete_previous_pending_document

  after_destroy :create_history
  after_destroy :recalculate_scores
  after_save :create_history, if: :saved_changes?
  after_save :recalculate_scores, if: :saved_change_to_score_related_attributes?
  after_save :remove_notifications, if: :saved_change_to_expire_date?

  after_commit :notify_about_changes, if: :saved_change_to_status?

  scope :by_forest_types, ->(forest_type_id) { includes(:fmu).where(fmus: {forest_type: forest_type_id}) }
  scope :by_country, ->(country_id) { includes(:required_operator_document).where(required_operator_documents: {country_id: country_id}) }
  scope :by_required_operator_document_group, ->(required_operator_document_group_id) { includes(:required_operator_document).where(required_operator_documents: {required_operator_document_group_id: required_operator_document_group_id}) }
  scope :exclude_by_required_operator_document_group, ->(required_operator_document_group_id) { includes(:required_operator_document).where.not(required_operator_documents: {required_operator_document_group_id: required_operator_document_group_id}) }
  scope :fmu_type, -> { where(type: "OperatorDocumentFmu") }
  scope :country_type, -> { where(type: "OperatorDocumentCountry") }
  scope :from_active_operators, -> { joins(:operator).where(operators: {is_active: true}) }
  scope :approved, -> { where(status: %i[doc_valid doc_not_required]) }
  scope :valid, -> { where(status: :doc_valid) }
  scope :required, -> { where.not(status: :doc_not_required) }
  scope :from_user, ->(operator_id) { where(operator_id: operator_id) }
  scope :by_source, ->(source_id) { where(source: source_id) }
  scope :available, -> { where(public: true) }
  scope :expirable, -> { where(status: EXPIRABLE_STATUSES) }
  scope :signature, -> {
                      joins(:required_operator_document).where(required_operator_documents: {contract_signature: true})
                    }
  scope :non_signature, -> {
                          joins(:required_operator_document).where(required_operator_documents: {contract_signature: false})
                        }                                                  # non signature
  scope :to_expire, ->(date) {
                      expirable
                        .joins(:required_operator_document)
                        .where("expire_date < ?", date)
                        .where(required_operator_documents: {contract_signature: false})
                    }

  enum status: {doc_not_provided: 0, doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4, doc_not_required: 5}
  enum uploaded_by: {operator: 1, monitor: 2, admin: 3, other: 4}
  enum source: {company: 1, forest_atlas: 2, other_source: 3}

  NON_HISTORICAL_ATTRIBUTES = %w[id attachment updated_at created_at].freeze
  EXPIRABLE_STATUSES = %w[doc_valid doc_not_required]

  def self.expire_documents
    documents_to_expire = OperatorDocument.to_expire(Time.zone.today)
    number_of_documents = documents_to_expire.count
    documents_to_expire.find_each(&:expire_document)
    Rails.logger.info "Expired #{number_of_documents} documents"
  end

  def build_history
    mapping = attributes.except(*NON_HISTORICAL_ATTRIBUTES)
    mapping["operator_document_id"] = id
    # we will copy object timestamps and keep using Rails timestamps
    # as how they normally are used, to know when history was created
    mapping["operator_document_updated_at"] = updated_at
    mapping["operator_document_created_at"] = created_at
    mapping["type"] += "History"
    OperatorDocumentHistory.new mapping
  end

  # Creates an OperatorDocumentHistory for the current OperatorDocument
  def create_history
    odh = build_history
    odh.operator_document_annexes = operator_document_annexes
    odh.save!
  end

  def set_expire_date
    self.expire_date = begin
      start_date + required_operator_document.valid_period.days
    rescue
      start_date
    end
  end

  def expire_document
    destroy! if status == "doc_not_required" # that would regenerate with not_provided state
    update!(status: "doc_expired") if status == "doc_valid"
  end

  # When a doc is valid or not required
  def approved?
    %w[doc_not_required doc_valid].include?(status)
  end

  def name_with_fmu
    return required_operator_document.name if fmu.nil?

    "#{required_operator_document.name} (#{fmu.name})"
  end

  def destroy # rubocop:disable Rails/ActiveRecordOverride
    # It only allows for (soft) deletion of the operator documents when:
    # 1 - The Operator was deleted  (destroyed_by_association)
    # 2 - The Fmu was deleted (destroyed_by_association)
    # 3 - The Required Operator Document was deleted (destroyed_by_association)
    # 4 - The Operator is no longer active for this Fmu
    return super if destroyed_by_association || (fmu_id && (operator_id != fmu.operator&.id))

    update!(
      status: OperatorDocument.statuses[:doc_not_provided],
      expire_date: nil, start_date: Time.zone.today, created_at: DateTime.now, updated_at: DateTime.now,
      deleted_at: nil, uploaded_by: nil, user_id: nil, reason: nil, note: nil, response_date: nil,
      source: nil, source_info: nil, document_file_id: nil
    )
  end

  private

  def recalculate_scores
    return if skip_score_recalculation

    ScoreOperatorDocument.recalculate!(operator)
  end

  def saved_change_to_score_related_attributes?
    saved_change_to_status? || (!operator.approved? && saved_change_to_public?)
  end

  def set_type
    return if type.present?

    self.type = "OperatorDocumentFmu" if required_operator_document.is_a?(RequiredOperatorDocumentFmu)
    self.type = "OperatorDocumentCountry" if required_operator_document.is_a?(RequiredOperatorDocumentCountry)
  end

  # Removes the existing notifications for an operator document
  # as long as the new expire date is longer than the notification period or the group has been removed
  def remove_notifications
    Notification.includes(:notification_group).unsolved.where(operator_document_id: id).find_each do |notification|
      notification.solve! and next unless notification.notification_group_id
      next if Time.zone.today + notification.notification_group.days > expire_date

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
    pending_documents = OperatorDocument.where(operator_id: operator_id,
      fmu_id: fmu_id,
      required_operator_document_id: required_operator_document_id,
      status: OperatorDocument.statuses[:doc_pending])
    pending_documents.each { |x| x.destroy }
  end

  def reason_or_file
    if document_file.present? && reason.present?
      errors.add(:base, "Could either have uploaded file or reason of document non applicability")
    end
    if document_file.blank? && reason.blank? && !doc_not_provided?
      errors.add(:base, "File must be present or reason when document is non applicable")
    end
  end

  def notify_about_changes
    notify_users(operator.all_users, "document_valid") if doc_valid?
    notify_users(operator.all_users, "document_accepted_as_not_required") if doc_not_required?
    notify_users(operator.all_users, "document_invalid") if doc_invalid?
    notify_users(operator.responsible_admins, "admin_document_pending") if doc_pending?
  end

  def notify_users(users, mail_template)
    users.filter_actives.where.not(email: [nil, ""]).find_each do |user|
      I18n.with_locale(user.locale.presence || I18n.default_locale) do
        OperatorDocumentMailer.send(mail_template, self, user).deliver_later
      end
    end
  end
end
