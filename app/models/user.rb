# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                   :integer          not null, primary key
#  email                :string
#  password_digest      :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  nickname             :string
#  name                 :string
#  institution          :string
#  web_url              :string
#  is_active            :boolean          default(TRUE)
#  deactivated_at       :datetime
#  permissions_request  :integer
#  permissions_accepted :datetime
#  country_id           :integer
#

class User < ApplicationRecord
  has_secure_password

  enum permissions_request: { operator: 1, ngo: 2 }

  # Include default devise modules.
  TEMP_EMAIL_REGEX = /\Achange@tmp/

  belongs_to :country, inverse_of: :users, optional: true

  has_one  :api_key
  has_one  :user_permission
  has_many :observations, inverse_of: :user
  has_many :comments,     inverse_of: :user, dependent: :destroy

  has_many :user_observers
  has_many :user_operators
  has_many :observers, through: :user_observers
  has_many :operators, through: :user_operators

  accepts_nested_attributes_for :user_permission

  validates :nickname,    presence: true, uniqueness: { case_sensitive: false }
  validates_uniqueness_of :email
  validates_format_of     :email, without: TEMP_EMAIL_REGEX, on: :update
  validates :name,        presence: true
  validate  :validate_nickname

  validates_format_of :nickname, with: /\A[a-z0-9_\.][-a-z0-9]{1,19}\Z/i,
                                 exclusion: { in: %w(admin superuser about root fti otp faq conntact user operator ngo) },
                                 multiline: true

  validates :password, confirmation: true
  validates :password_confirmation, presence: true, on: :create

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

    def user_select
      by_nickname_asc.map { |c| [c.nickname, c.id] }
    end
  end

  def display_name
    return "#{half_email}" if name.blank?
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
    if ::APIKey.where(user_id: id).first_or_create
      api_key.update(access_token: token, is_active: true, expires_at: DateTime.now + 1.year)
    end
  end

  def delete_api_key
    if self.api_key
      APIKey.where(user_id: self.id).delete_all
    end
  end

  private

    def validate_nickname
      if User.where(email: nickname).exists?
        errors.add(:nickname, :invalid)
      end
    end

    def half_email
      return "" if email.blank?
      index = email.index('@')
      return "" if index.nil? || index.to_i.zero?
      email[0, index.to_i]
    end
end
