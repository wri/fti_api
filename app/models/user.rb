# frozen_string_literal: true
# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  nickname               :string
#  name                   :string
#  institution            :string
#  web_url                :string
#  is_active              :boolean          default(TRUE)
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
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

  enum permissions_request: { operator: 1, ngo: 2 }

  # Include default devise modules.
  TEMP_EMAIL_REGEX = /\Achange@tmp/
  PERMISSIONS = %w(operator ngo)

  belongs_to :country, inverse_of: :users, optional: true

  has_one  :api_key
  has_one  :user_permission
  has_many :observations,             inverse_of: :user
  has_many :comments,                 inverse_of: :user, dependent: :destroy
  has_many :photos,                   inverse_of: :user
  has_many :observation_documents,    inverse_of: :user
  has_many :observation_reports,      inverse_of: :user

  belongs_to :observer, optional: true
  belongs_to :operator,  optional: true

  accepts_nested_attributes_for :user_permission

  before_validation :create_from_request

  validates :nickname,    presence: true, uniqueness: { case_sensitive: false }
  validates_uniqueness_of :email
  validates_format_of     :email, without: TEMP_EMAIL_REGEX, on: :update
  validates :name,        presence: true
  validate  :validate_nickname

  validates_format_of :nickname, with: /\A[a-z0-9_\.][-a-z0-9]{1,19}\Z/i,
                                 exclusion: { in: %w(admin superuser about root fti otp faq contact user operator ngo) },
                                 multiline: true

  validates :password, confirmation: true,
                       length: { within: 8..20 },
                       on: :create
  validates :password_confirmation, presence: true, on: :create
  validate :user_integrity

  include Activable
  include Roleable
  include Sanitizable

  scope :recent,          -> { order('users.updated_at DESC') }
  scope :by_nickname_asc, -> { order('users.nickname ASC')    }

  class << self
    def fetch_all(options)
      users = includes(:user_permission, :comments, :country)
      users
    end
  end

  def display_name
    "#{half_email}" if name.blank?
    "#{name}"
  end

  def active_for_authentication?
    super and self.is_active?
  end

  def inactive_message
    'You are not allowed to sign in.'
  end

  def api_key_exists?
    !self.api_key.expired? if self.api_key.present?
  end

  def regenerate_api_key
    token = Auth.issue({ user: id })
    api_key = ::APIKey.where(user_id: id).first_or_create
    api_key.update(access_token: token, is_active: true, expires_at: DateTime.now + 1.year)
  end

  def delete_api_key
    if self.api_key
      APIKey.where(user_id: self.id).delete_all
    end
  end

  def send_reset_password_instructions(options)
    reset_url  = options[:reset_url]
    reset_url += '?reset_password_token='
    reset_url += generate_reset_token(self)

    PasswordMailer.password_email(display_name, email, reset_url).deliver
  end

  def reset_password_by_token(options)
    if reset_password_sent_at.present? && DateTime.now <= reset_password_sent_at + 2.hours
      update(password: options[:password],
             password_confirmation: options[:password_confirmation],
             reset_password_sent_at: nil)
    else
      self.errors.add(:reset_password_token, 'link expired.')
      self
    end
  end

  def reset_password_by_current_user(options)
    if update(password: options[:password],
              password_confirmation: options[:password_confirmation])
      self
    else
      self.errors.add(:password, 'could not be updated!')
      self
    end
  end

  private

  def create_from_request
    return unless permissions_request.present?
    self.user_permission = UserPermission.new(user_role: permissions_request)

  end

  def generate_reset_token(user)
    token = SecureRandom.uuid
    user.update(reset_password_token: token, reset_password_sent_at: DateTime.now)
    user.reset_password_token
  end

  def validate_nickname
    if User.where(email: nickname).exists?
      errors.add(:nickname, :invalid)
    end
  end

  def half_email
    "" if email.blank?
    index = email.index('@')
    "" if index.nil? || index.to_i.zero?
    email[0, index.to_i]
  end

def user_integrity
  if user_permission.blank?
    errors['user_permission'] << 'You must choose a user permission'
  else
    case user_permission.user_role
      when 'operator'
        errors['operator_id'] << 'User of type Operator must have an operator and no observer' unless operator.present? && observer_id.blank?
      when 'ngo'
        errors['observer_id'] << 'User of type NGO must have an observer and no operator' unless observer.present? && operator_id.blank?
      else
        errors['operator_id'] << 'Cannot have an Operator' unless operator_id.blank?
        errors['observer_id'] << 'Cannot have an Observer' unless observer_id.blank?
    end
  end
end
end
