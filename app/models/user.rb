# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  name                   :string
#  institution            :string
#  web_url                :string
#  is_active              :boolean          default(TRUE), not null
#  deactivated_at         :datetime
#  permissions_request    :integer
#  permissions_accepted   :datetime
#  country_id             :integer
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  encrypted_password     :string           default(""), not null
#  remember_created_at    :datetime
#  observer_id            :integer
#  operator_id            :integer
#  holding_id             :integer
#  locale                 :string
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
    :recoverable, :rememberable, :trackable, :validatable

  # Include default devise modules.
  TEMP_EMAIL_REGEX = /\Achange@tmp/
  PERMISSIONS = %w[operator ngo ngo_manager government]
  PROTECTED_NICKNAMES = %w[admin superuser about root fti otp faq contact user operator ngo].freeze
  enum permissions_request: {operator: 1, ngo: 2, ngo_manager: 4, government: 6, holding: 7}

  belongs_to :country, inverse_of: :users, optional: true

  has_one :api_key, dependent: :destroy
  has_one :user_permission
  has_many :observations, inverse_of: :user
  has_many :comments, inverse_of: :user, dependent: :destroy
  has_many :observation_documents, inverse_of: :user
  has_many :observation_reports, inverse_of: :user
  has_many :operator_document_annexes, inverse_of: :user

  belongs_to :observer, optional: true
  belongs_to :operator, optional: true
  belongs_to :holding, optional: true

  accepts_nested_attributes_for :user_permission

  validates :email, uniqueness: true
  validates :email, format: {without: TEMP_EMAIL_REGEX, on: :update}
  validates :name, presence: true
  validates :locale, inclusion: {in: I18n.available_locales.map(&:to_s), allow_blank: true}
  validates :password, confirmation: true,
    length: {within: 8..20},
    on: :create
  validates :password_confirmation, presence: true, on: :create
  validate :user_integrity

  before_validation :create_from_request, on: :create
  after_update :notify_user, if: -> { is_active && saved_change_to_is_active? }

  include Activable
  include Roleable
  include Sanitizable

  scope :recent, -> { order("users.updated_at DESC") }
  scope :inactive, -> { where(is_active: false) }
  scope :with_user_role, ->(role) { joins(:user_permission).where(user_permission: {user_role: role}) }

  class << self
    def fetch_all(options)
      includes(:user_permission, :comments, :country)
    end
  end

  def is_government(country_id)
    self&.user_permission&.user_role == "government" && self.country_id == country_id
  end

  def is_operator?(operator_id)
    return true if self&.user_permission&.user_role == "operator" && self.operator_id == operator_id

    is_operator_holding? operator_id
  end

  def is_operator_holding?(operator_id)
    return false unless self&.user_permission&.user_role == "holding"

    Operator.find_by(id: operator_id)&.holding_id == holding_id
  end

  def operator_ids
    return [operator_id] if operator_id.present?
    return holding.operators.pluck(:id) if holding_id.present?

    []
  end

  def display_name
    name.present? ? name.to_s : half_email.to_s
  end

  def active_for_authentication?
    super and is_active?
  end

  def inactive_message
    "You are not allowed to sign in."
  end

  def api_key_exists?
    # TODO Should return true/false but not nil
    !api_key.expired? if api_key.present?
  end

  def regenerate_api_key
    token = Auth.issue({user: id})
    api_key = ::APIKey.where(user_id: id).first_or_create
    api_key.update(access_token: token, is_active: true, expires_at: DateTime.now + 1.year)
  end

  def delete_api_key
    APIKey.where(user_id: id).delete_all if api_key
  end

  def send_reset_password_instructions
    I18n.with_locale(locale.presence || I18n.default_locale) do
      UserMailer.forgotten_password(self).deliver_later
    end
  end

  def organization_name
    return operator.name if operator.present? && user_permission&.user_role&.operator?
    return observer.name if observer.present? && user_permission&.user_role&.starts_with?("ngo")
    return country.name if country.present? && user_permission&.government?

    nil
  end

  private

  def create_from_request
    return if permissions_request.blank?

    self.user_permission = UserPermission.new(user_role: permissions_request)
    self.permissions_request = nil
  end

  def generate_reset_token(user)
    token = SecureRandom.uuid
    user.update(reset_password_token: token, reset_password_sent_at: DateTime.now)
    user.reset_password_token
  end

  def half_email
    return "" if email.blank?

    index = email.index("@")
    return "" if index.nil? || index.to_i.zero?

    email[0, index.to_i]
  end

  def user_integrity
    if user_permission.blank?
      errors.add(:user_permission, "You must choose a user permission")
      return
    end

    case user_permission.user_role
    when "operator"
      if operator_id.blank? || observer_id.present? || holding_id.present?
        errors.add(:operator_id, "User of type Operator must have an operator and no observer or holding")
      end
    when "ngo", "ngo_manager"
      if operator_id.present? || observer_id.blank? || holding_id.present?
        errors.add(:observer_id, "User of type NGO must have an observer and no operator or holding")
      end
    when "holding"
      if holding_id.blank? || observer_id.present? || operator_id.present?
        errors.add(:holding_id, "User of type Holding must have a holding and no operator or observer")
      end
    else
      errors.add(:operator_id, "Cannot have an Operator") if operator_id.present?
      errors.add(:observer_id, "Cannot have an Observer") if observer_id.present?
    end
  end

  # Sends an email to the user when it is approved
  def notify_user
    UserMailer.user_acceptance(self).deliver_later
  end

  # Devise ActiveJob integration
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
