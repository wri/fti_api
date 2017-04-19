# frozen_string_literal: true

# == Schema Information
#
# Table name: observers
#
#  id            :integer          not null, primary key
#  observer_type :string           not null
#  country_id    :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  is_active     :boolean          default(TRUE)
#  logo          :string
#

class Observer < ApplicationRecord
  translates :name, :organization

  mount_base64_uploader :logo, LogoUploader

  belongs_to :country, inverse_of: :observers, optional: true

  has_many :observations, inverse_of: :observer
  has_many :user_observers
  has_many :users, through: :user_observers

  validates :name, presence: true
  validates :observer_type, presence: true, inclusion: { in: %w(Mandated SemiMandated External Government),
                                                         message: "%{value} is not a valid observer type" }

  scope :by_name_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
                           .order('observer_translations.name ASC')
  }

  default_scope { includes(:translations) }

  class << self
    def fetch_all(options)
      observers = by_name_asc
      observers
    end

    def observer_select
      by_name_asc.map { |c| ["#{c.name} (#{c.observer_type})", c.id] }
    end

    def types
      %w(Mandated SemiMandated External Government).freeze
    end

    def translated_types
      types.map { |t| [I18n.t("observer_types.#{t}", default: t), t.camelize] }
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end
