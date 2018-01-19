# frozen_string_literal: true

# == Schema Information
#
# Table name: observations
#
#  id                    :integer          not null, primary key
#  severity_id           :integer
#  observation_type      :integer          not null
#  user_id               :integer
#  publication_date      :datetime
#  country_id            :integer
#  operator_id           :integer
#  government_id         :integer
#  pv                    :string
#  is_active             :boolean          default(TRUE)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  lat                   :decimal(, )
#  lng                   :decimal(, )
#  fmu_id                :integer
#  subcategory_id        :integer
#  validation_status     :integer          default("Created"), not null
#  observation_report_id :integer
#  actions_taken         :text
#  modified_user_id      :integer
#  law_id                :integer
#

class Observation < ApplicationRecord
  include Translatable
  include ValidationHelper
  translates :details, :evidence, :concern_opinion, :litigation_status, touch: true
  active_admin_translates :details, :evidence, :concern_opinion, :litigation_status

  enum observation_type: %w(operator government)
  enum validation_status: ['Created', 'Ready for revision', 'Under revision', 'Approved', 'Rejected']


  belongs_to :country,        inverse_of: :observations
  belongs_to :severity,       inverse_of: :observations
  belongs_to :operator,       inverse_of: :observations, optional: true
  belongs_to :government,     inverse_of: :observations, optional: true
  belongs_to :user,           inverse_of: :observations, optional: true
  belongs_to :modified_user,  class_name: 'User', foreign_key: 'modified_user_id', optional: true
  belongs_to :fmu,            inverse_of: :observations, optional: true
  belongs_to :law,            inverse_of: :observations, optional: true

  belongs_to :subcategory, inverse_of: :observations, optional: true

  has_many :species_observations
  has_many :species, through: :species_observations

  has_many :observer_observations, dependent: :destroy
  has_many :observers, through: :observer_observations

  has_many :observation_operators, dependent: :destroy
  has_many :relevant_operators, through: :observation_operators, source: :operator

  has_many :comments,  as: :commentable
  has_many :photos,    as: :attacheable, dependent: :destroy
  has_many :observation_documents
  belongs_to :observation_report

  accepts_nested_attributes_for :photos,                       allow_destroy: true
  accepts_nested_attributes_for :observation_documents,        allow_destroy: true
  accepts_nested_attributes_for :observation_report,           allow_destroy: true
  accepts_nested_attributes_for :subcategory,                  allow_destroy: false


  validates :country_id,       presence: true
  validates :publication_date, presence: true
  validates_presence_of :validation_status
  validates_presence_of :observation_type
  validate :active_government

  before_save    :set_active_status
  before_save    :set_centroid
  after_create   :update_operator_scores
  before_destroy :destroy_documents
  after_destroy  :update_operator_scores
  after_save     :update_operator_scores,   if: 'publication_date_changed? || severity_id_changed? || is_active_changed?'
  after_save     :update_reports_observers, if: 'observation_report_id_changed?'

  include Activable

  scope :active, ->() { joins(:translations).where(is_active: true) }
  scope :own_with_inactive, ->(observer) {
    joins('INNER JOIN "observer_observations" ON "observer_observations"."observation_id" = "observations"."id"
INNER JOIN "observers" as "all_observers" ON "observer_observations"."observer_id" = "all_observers"."id"')
        .where("all_observers.id = #{observer}")
  }

  scope :pending, ->() { joins(:translations).where(validation_status: ['Created', 'Under revision']) }
  scope :created, ->() { joins(:translations).where(validation_status: ['Created', 'Ready for revision']) }

  class << self
    def translated_types
      types.map { |t| [I18n.t("observation_types.#{t}", default: t), t.camelize] }
    end
  end

  def user_name
    self.try(:user).try(:name)
  end

  def translated_type
    I18n.t("observation_types.#{observation_type.constantize}")
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end

  def update_reports_observers
    return if observation_report.blank?
    observation_report.observer_ids =
      observation_report.observations.map(&:observers).map(&:ids).flatten
  end


  private

  def set_centroid
    if fmu.present? && lat.blank? && lng.blank?
      self.lat = fmu.geojson.dig('properties', 'centroid', 'coordinates').first rescue nil
      self.lng = fmu.geojson.dig('properties', 'centroid', 'coordinates').second rescue nil

    end
  end

  def update_operator_scores
    operator&.calculate_observations_scores
  end

  def set_active_status
    self.is_active = self.validation_status == 'Approved' ? true : false
    nil
  end

  def destroy_documents
    observation_documents.find_each(&:really_destroy!)
  end

  def active_government
    return if observation_type != 'government'
    return if persisted?
    return if government.nil?
    errors[:government] << 'The selected government is not active' unless government.is_active
  end
end
