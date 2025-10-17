# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_reports
#
#  id               :integer          not null, primary key
#  title            :string
#  publication_date :datetime
#  attachment       :string
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  deleted_at       :datetime
#

class ObservationReport < ApplicationRecord
  has_paper_trail
  mount_base64_uploader :attachment, ObservationReportUploader

  acts_as_paranoid

  enum :mission_type, {mandated: 0, semi_mandated: 1, external: 2, government: 3}, prefix: true, scopes: false
  ransacker :mission_type, formatter: proc { |v| mission_types[v] }

  normalizes :title, with: -> { it.strip }

  # TODO: in DB user is nil in most records, is that a bug or not? Adding optional otherwise
  # API creating report fails as it's not providing user. Thing to investigate
  belongs_to :user, inverse_of: :observation_reports, optional: true
  has_many :observation_report_observers, dependent: :destroy
  has_many :observers, through: :observation_report_observers, after_add: :self_touch, after_remove: :self_touch
  has_many :observations, dependent: :destroy
  has_many :observation_documents, inverse_of: :observation_report, dependent: :destroy

  validates :attachment, presence: true
  validates :observers, presence: true
  validates :title, presence: true
  validates :publication_date, presence: true

  skip_callback :commit, :after, :remove_attachment!
  after_real_destroy :remove_attachment!

  attr_accessor :skip_observers_sync
  after_commit :sync_observation_observers, unless: :skip_observers_sync

  scope :bigger_date, ->(date) { where("observation_reports.created_at <= ?", date + 1.day) }

  def translated_mission_type
    I18n.t("activerecord.enums.observation_report.mission_types.#{mission_type}") if mission_type.present?
  end

  def self.translated_mission_types
    mission_types.map { |key, value| [I18n.t("activerecord.enums.observation_report.mission_types.#{key}"), key] }
  end

  private

  def self_touch(_)
    touch unless destroyed? || new_record?
  end

  def sync_observation_observers
    observations.with_deleted.find_each do |observation|
      observation.observers = observers
    end
  end
end
