# frozen_string_literal: true

# == Schema Information
#
# Table name: observers
#
#  id                   :integer          not null, primary key
#  observer_type        :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  is_active            :boolean          default(TRUE), not null
#  logo                 :string
#  address              :string
#  information_name     :string
#  information_email    :string
#  information_phone    :string
#  data_name            :string
#  data_email           :string
#  data_phone           :string
#  organization_type    :string
#  public_info          :boolean          default(FALSE), not null
#  responsible_admin_id :integer
#  name                 :string           not null
#

class Observer < ApplicationRecord
  has_paper_trail

  mount_base64_uploader :logo, LogoUploader
  attr_accessor :delete_logo

  has_many :countries_observers
  has_many :countries, through: :countries_observers

  has_many :observer_observations, dependent: :restrict_with_error
  has_many :observations, through: :observer_observations

  has_many :observation_report_observers, dependent: :restrict_with_error
  has_many :observation_reports, through: :observation_report_observers

  has_many :users, inverse_of: :observer
  has_and_belongs_to_many :managers, join_table: "observer_managers", class_name: "User", dependent: :destroy

  belongs_to :responsible_admin, class_name: "User", optional: true

  EMAIL_VALIDATOR = /\A([\w+-].?)+@[a-z\d-]+(\.[a-z]+)*\.[a-z]+\z/i

  before_validation { remove_logo! if delete_logo == "1" }
  validates :name, presence: true
  validates :observer_type, presence: true, inclusion: {in: %w[Mandated SemiMandated External Government],
                                                        message: "%{value} is not a valid observer type"}
  validates :organization_type,
    inclusion: {in: ["NGO", "Academic", "Research Institute", "Private Company", "Other"]}, if: :organization_type?

  validates :information_email, format: {with: EMAIL_VALIDATOR, if: :information_email?}
  validates :data_email, format: {with: EMAIL_VALIDATOR, if: :data_email?}

  before_create :set_responsible_admin

  scope :by_name_asc, -> { order(name: :asc) }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }
  scope :with_at_least_one_report, -> { where(id: ObservationReport.joins(:observers).select("observers.id").distinct.select("observers.id")) }

  class << self
    def observer_select
      by_name_asc.map { |c| ["#{c.name} (#{c.observer_type})", c.id] }
    end

    def types
      %w[Mandated SemiMandated External Government].freeze
    end

    def translated_types
      types.map { |t| [I18n.t("observer_types.#{t}", default: t), t.camelize] }
    end
  end

  def cache_key
    super + "-" + Globalize.locale.to_s
  end

  # Sets the default responsible admin for an observer
  #
  def set_responsible_admin
    return if responsible_admin.present?

    self.responsible_admin = User.where(email: ENV["RESPONSIBLE_EMAIL"].downcase).first
  end
end
