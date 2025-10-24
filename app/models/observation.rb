# frozen_string_literal: true

# == Schema Information
#
# Table name: observations
#
#  id                                :integer          not null, primary key
#  severity_id                       :integer
#  observation_type                  :integer          not null
#  user_id                           :integer
#  publication_date                  :datetime
#  country_id                        :integer
#  operator_id                       :integer
#  pv                                :string
#  is_active                         :boolean          default(TRUE), not null
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  lat                               :decimal(, )
#  lng                               :decimal(, )
#  fmu_id                            :integer
#  subcategory_id                    :integer
#  validation_status                 :integer          default("Created"), not null
#  observation_report_id             :integer
#  actions_taken                     :text
#  modified_user_id                  :integer
#  law_id                            :integer
#  location_information              :string
#  is_physical_place                 :boolean          default(TRUE), not null
#  evidence_type                     :integer
#  location_accuracy                 :integer
#  evidence_on_report                :string
#  hidden                            :boolean          default(FALSE), not null
#  admin_comment                     :text
#  monitor_comment                   :text
#  deleted_at                        :datetime
#  locale                            :string
#  non_concession_activity           :boolean          default(FALSE), not null
#  details                           :text
#  concern_opinion                   :text
#  litigation_status                 :string
#  deleted_at                        :datetime
#  details_translated_from           :string
#  concern_opinion_translated_from   :string
#  litigation_status_translated_from :string
#

class Observation < ApplicationRecord
  has_paper_trail
  acts_as_paranoid

  include Translatable
  include Activable
  include ValidationHelper
  include ObservationOldAttributes

  translates :details, :concern_opinion, :litigation_status, touch: true, versioning: :paper_trail, paranoia: true
  active_admin_translates :details, :concern_opinion, :litigation_status

  WrongStateError = Class.new(StandardError)

  enum :evidence_type, {"No evidence" => 0, "Uploaded documents" => 1, "Evidence presented in the report" => 2}, validate: {allow_nil: true}
  enum :observation_type, {"operator" => 0, "government" => 1}, validate: true
  enum :validation_status, {
    "Created" => 0,
    "Ready for QC1" => 10,
    "QC1 in progress" => 11,
    "Ready for QC2" => 1,
    "QC2 in progress" => 2,
    "Approved" => 3,
    "Rejected" => 4,
    "Needs revision" => 5,
    "Ready for publication" => 6,
    "Published (no comments)" => 7,
    "Published (not modified)" => 8,
    "Published (modified)" => 9
  }
  enum :location_accuracy, {
    "Estimated location" => 0, "GPS coordinates extracted from photo" => 1, "Accurate GPS coordinates" => 2
  }, validate: {allow_nil: true}

  AUTOMATICALLY_TRANSLATABLE_FIELDS = %w[details concern_opinion litigation_status]

  STATUS_TRANSITIONS = {
    monitor: {
      "Created" => ["Ready for QC2", "Ready for QC1"],
      "Rejected" => ["Ready for QC1"],
      "Needs revision" => ["Ready for QC2", "Published (not modified)", "Published (modified)"],
      "Ready for publication" => ["Published (no comments)"],
      "Published (modified)" => ["Ready for QC2", "Ready for QC1"],
      "Published (not modified)" => ["Ready for QC2", "Ready for QC1"],
      "Published (no comments)" => ["Ready for QC2", "Ready for QC1"]
    },
    reviewer: {
      "Ready for QC1" => ["QC1 in progress"],
      "QC1 in progress" => ["Rejected", "Ready for QC2"],
      "Ready for QC2" => ["QC2 in progress"],
      "QC2 in progress" => ["Needs revision", "Ready for publication"]
    }
  }.freeze

  QC_APPROVAL_STATUS_TRANSITIONS = {
    "QC1 in progress" => {
      false => "Rejected",
      true => "Ready for QC2"
    },
    "QC2 in progress" => {
      false => "Needs revision",
      true => "Ready for publication"
    }
  }.freeze

  PUBLISHED_STATES = [
    "Published (modified)",
    "Published (not modified)",
    "Published (no comments)"
  ].freeze

  attr_accessor :user_type
  attr_accessor :force_translations_from

  belongs_to :country, inverse_of: :observations
  belongs_to :severity, inverse_of: :observations, optional: true
  belongs_to :operator, inverse_of: :observations, optional: true
  belongs_to :user, inverse_of: :observations, optional: true
  belongs_to :modified_user, class_name: "User", inverse_of: :modified_observations, optional: true
  belongs_to :fmu, inverse_of: :observations, optional: true
  belongs_to :law, inverse_of: :observations, optional: true
  belongs_to :observation_report, optional: true

  belongs_to :subcategory, inverse_of: :observations, optional: true

  has_many :quality_controls, as: :reviewable, dependent: :destroy
  has_one :latest_quality_control, -> { order(created_at: :desc) }, inverse_of: :reviewable, class_name: "QualityControl"

  has_many :species_observations, dependent: :destroy
  has_many :species, through: :species_observations

  has_many :governments_observations, dependent: :destroy
  has_many :governments, through: :governments_observations

  has_many :observer_observations, dependent: :destroy
  has_many :observers, through: :observer_observations

  has_many :observation_operators, dependent: :destroy
  has_many :relevant_operators, through: :observation_operators, source: :operator

  has_many :observation_documents_observations, dependent: :destroy
  has_many :observation_documents, through: :observation_documents_observations

  accepts_nested_attributes_for :observation_documents, allow_destroy: true
  accepts_nested_attributes_for :observation_report, allow_destroy: true
  accepts_nested_attributes_for :subcategory, allow_destroy: false

  with_options if: :operator? do
    validate :validate_governments_absences
    validate :validate_known_operator, if: -> { operator? && (validation_status != "Created") }
  end

  with_options if: :government? do
    validates :operator_id, absence: true
    validate :active_government
  end

  validates :lat, numericality: {greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_blank: true}
  validates :lng, numericality: {greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_blank: true}
  validates :evidence_on_report, presence: true, if: -> { evidence_type == "Evidence presented in the report" }
  validate :status_changes, if: -> { user_type.present? }
  validate :can_set_non_concession_activity, if: -> { non_concession_activity? }

  validates :observers, presence: true
  validates :observation_type, presence: true

  validates :validation_status, presence: true

  with_options unless: -> { Created? || Rejected? } do
    validates :subcategory, presence: true
    validates :severity, presence: true
    validates :observation_report, presence: true
    validates :evidence_type, presence: true
  end

  before_validation :assign_observers_from_report, if: :observation_report_changed?
  before_validation :nullify_evidence_on_report, if: -> { evidence_type != "Evidence presented in the report" }

  before_save :set_active_status
  before_save :nullify_fmu_and_coordinates, unless: :is_physical_place
  before_save :set_centroid
  before_save :set_publication_date, if: :validation_status_changed?
  before_create :set_default_observer

  after_create :update_operator_scores, if: :is_active?
  after_update :update_operator_scores, if: -> { saved_change_to_publication_date? || saved_change_to_severity_id? || saved_change_to_is_active? || saved_change_to_operator_id? || saved_change_to_fmu_id? }

  after_destroy :update_operator_scores
  after_destroy :update_fmu_geojson

  after_save :create_history, if: :saved_changes?

  after_save :remove_documents, if: -> { evidence_type != "Uploaded documents" }
  after_save :update_fmu_geojson
  after_save :force_translations

  after_commit :notify_about_creation, on: :create
  after_commit :notify_about_changes, if: :saved_change_to_validation_status?

  # TODO Check if we can change the joins with a with_translations(I18n.locale)
  scope :active, -> { includes(:translations).where(is_active: true).visible }
  scope :own_with_inactive, ->(observer_id) {
    joins(
      <<~SQL
        INNER JOIN "observer_observations" ON "observer_observations"."observation_id" = "observations"."id"
        INNER JOIN "observers" as "all_observers" ON "observer_observations"."observer_id" = "all_observers"."id"
      SQL
    ).where(all_observers: {id: observer_id})
  }

  scope :by_category, ->(category_id) { joins(:subcategory).where(subcategories: {category_id: category_id}) }
  scope :by_severity_level, ->(level) { joins(:subcategory).joins("inner join severities sevs on subcategories.id = sevs.subcategory_id and observations.severity_id = sevs.id").where(sevs: {level: level}) }
  scope :by_government, ->(government_id) { joins(:governments).where(governments: {id: government_id}) }
  scope :pending, -> { where(validation_status: ["Created", "QC2 in progress"]) }
  scope :created, -> { where(validation_status: ["Created", "Ready for QC2"]) }
  scope :published, -> { where(validation_status: PUBLISHED_STATES) }
  scope :hidden, -> { where(hidden: true) }
  scope :visible, -> { where(hidden: [false, nil]) }
  scope :order_by_category, ->(order = "ASC") { joins("inner join subcategories s on observations.subcategory_id = s.id inner join categories c on s.category_id = c.id inner join category_translations ct on ct.category_id = c.id and ct.locale = '#{I18n.locale}'").order("ct.name" => order) }
  scope :bigger_date, ->(date) { where("observations.created_at <= ?", date + 1.day) }
  scope :to_be_hidden, -> { published.where(hidden: [nil, false]).joins(:observation_report).where(observation_reports: {publication_date: ...5.years.ago}) }

  class << self
    def translated_types
      observation_types.map { |t| [I18n.t("observation_types.#{t.first}", default: t.first), t.first.camelize] }
    end
  end

  def translated_type
    I18n.t("observation_types.#{observation_type}")
  end

  def cache_key
    super + "-" + Globalize.locale.to_s
  end

  def update_reports_observers
    return if observation_report.blank?

    observation_report.update_observers
  end

  HISTORICAL_ATTRIBUTES = %w[fmu_id operator_id country_id subcategory_id observation_type location_accuracy validation_status is_active hidden deleted_at]

  # Creates an ObservationHistory for the current Observation
  def create_history
    mapping = attributes.slice(*HISTORICAL_ATTRIBUTES)
    mapping["observation_id"] = id
    mapping["category_id"] = subcategory&.category_id
    mapping["severity_level"] = severity&.level
    mapping["fmu_forest_type"] = fmu&.forest_type
    # we will copy object timestamps and keep using Rails timestamps
    # as how they normally are used, to know when history was created
    mapping["observation_updated_at"] = updated_at
    mapping["observation_created_at"] = created_at
    ObservationHistory.create! mapping
  end

  def published?
    PUBLISHED_STATES.include?(validation_status)
  end

  def qc_in_progress?
    validation_status.in?(["QC1 in progress", "QC2 in progress"])
  end

  def qc1_needed?
    observers.any?(&:responsible_qc1_id)
  end

  def responsible_for_qc1
    User.where(id: observers.pluck(:responsible_qc1_id))
  end

  def responsible_for_qc2
    User.where(id: observers.pluck(:responsible_qc2_id))
  end

  def all_responsible_for_qc
    responsible_for_qc1.or(responsible_for_qc2)
  end

  def update_qc_status!(qc_passed:)
    raise WrongStateError, "QC not in progress" unless qc_in_progress?

    update!(
      user_type: :reviewer,
      validation_status: QC_APPROVAL_STATUS_TRANSITIONS[validation_status][qc_passed]
    )
  end

  def qc_available_decisions
    return [] unless QC_APPROVAL_STATUS_TRANSITIONS[validation_status]

    QC_APPROVAL_STATUS_TRANSITIONS[validation_status].invert.to_a
  end

  def qc_metadata(qc_passed:)
    return {} unless qc_in_progress?

    {
      level: (validation_status == "QC1 in progress") ? "QC1" : "QC2",
      decision: QC_APPROVAL_STATUS_TRANSITIONS[validation_status][qc_passed]
    }
  end

  def non_concession_activity_enabled?
    country&.iso == "COD"
  end

  private

  def nullify_evidence_on_report
    self.evidence_on_report = nil
  end

  def nullify_fmu_and_coordinates
    self.lat = nil
    self.lng = nil
    self.fmu = nil
  end

  def set_publication_date
    self.publication_date = Time.zone.now if published?
  end

  def set_centroid
    return if fmu.blank? || lat.present? || lng.present?

    self.lng = begin
      fmu.geojson.dig("properties", "centroid", "coordinates").first
    rescue
      nil
    end
    self.lat = begin
      fmu.geojson.dig("properties", "centroid", "coordinates").second
    rescue
      nil
    end
  end

  def update_operator_scores
    ScoreOperatorObservation.recalculate! operator if operator.present?
    return unless operator_id_was == operator_id

    old_operator = Operator.find_by id: operator_id_was
    ScoreOperatorObservation.recalculate! old_operator if old_operator.present?
  end

  def set_active_status
    self.is_active = published? && hidden != true
  end

  # If user is set for observation and user has observer account
  # then it becomes default observer if not set
  def set_default_observer
    return if observers.present?
    return if user.nil?
    return if user.observer.nil?

    observers << user.observer
  end

  def active_government
    return if persisted? ||
      governments.none? ||
      governments.select { |g| g.is_active? }.any?(&:is_active)

    errors.add(:governments, "At least one government should be active")
  end

  def validate_governments_absences
    return if governments.none?

    errors.add(:governments, "Should have no governments with 'operator' type")
  end

  def validate_known_operator
    errors.add(:operator, "can't be blank or unknown") if operator.blank? || operator.special_unknown?
  end

  # Validates the statuses transitions.
  # This method makes sure the state machine of observations' statuses is enforced.
  def status_changes
    return if validation_status == validation_status_was
    return if STATUS_TRANSITIONS.dig(@user_type, validation_status_was)&.include? validation_status

    errors.add(:validation_status,
      "Invalid validation change for #{@user_type}. Can't move from '#{validation_status_was}' to '#{validation_status}'")
  end

  def can_set_non_concession_activity
    errors.add(:non_concession_activity, :not_allowed_for_country) unless non_concession_activity_enabled?
  end

  def remove_documents
    self.observation_documents = []
  end

  # If the observation is for an fmu, it updates its geojson with the new count
  def update_fmu_geojson
    return unless fmu_id

    fmu.update_geojson_properties
    fmu.save
  end

  def assign_observers_from_report
    return if observation_report.nil?
    return if observation_report.observers.empty?

    self.observers = observation_report.observers
  end

  def notify_about_creation
    return unless validation_status == "Created"

    notify_observers "observation_created"
    notify_observer_managers "observation_created"
  end

  def notify_about_changes
    notify_reviewers "admin_observation_ready_for_qc", level: :qc1 if validation_status == "Ready for QC1"
    notify_reviewers "admin_observation_ready_for_qc", level: :qc2 if validation_status == "Ready for QC2"
    notify_reviewers "admin_observation_published_not_modified", level: :qc2 if validation_status == "Published (not modified)"
    notify_observers "observation_submitted_for_qc" if validation_status == "Ready for QC2"
    notify_observers "observation_needs_revision" if validation_status == "Needs revision" || validation_status == "Rejected"
    notify_observers "observation_ready_for_publication" if validation_status == "Ready for publication"
    notify_observers "observation_published" if published?
  end

  def notify_observers(mail_template)
    notify_users(
      User.where(id: observers.joins(:users).distinct.pluck("users.id")),
      mail_template
    )
  end

  def notify_observer_managers(mail_template)
    notify_users(
      User.where(id: observers.joins(:managers).distinct.pluck("observer_managers.user_id")),
      mail_template
    )
  end

  def notify_reviewers(mail_template, level:)
    notify_users(
      User.where(id: observers.distinct.pluck("responsible_#{level}_id")),
      mail_template
    )
  end

  def notify_users(users, mail_template)
    users.filter_actives.where.not(email: [nil, ""]).find_each do |user|
      I18n.with_locale(user.locale.presence || I18n.default_locale) do
        ObservationMailer.send(mail_template, self, user).deliver_later
      end
    end
  end

  def force_translations
    return unless published?
    return unless I18n.locale_available? force_translations_from

    TranslationJob.perform_later(self, force_translations_from)
  end
end
