# frozen_string_literal: true
# == Schema Information
#
# Table name: operators
#
#  id            :integer          not null, primary key
#  operator_type :string
#  country_id    :integer
#  concession    :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  is_active     :boolean          default(TRUE)
#  logo          :string
#  operator_id   :string
#

class Operator < ApplicationRecord
  translates :name, :details

  mount_base64_uploader :logo, LogoUploader

  belongs_to :country, inverse_of: :operators, optional: true

  has_many :observations, inverse_of: :operator
  has_many :user_operators
  has_many :users, through: :user_operators
  has_many :fmus, inverse_of: :operator

  has_many :operator_documents
  has_many :operator_document_countries
  has_many :operator_document_fmus

  after_create :create_operator_id

  validates :name, presence: true

  scope :by_name_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
                           .order('operator_translations.name ASC')
  }

  default_scope { includes(:translations) }

  scope :filter_by_country_ids,   ->(country_ids)     { where(country_id: country_ids.split(',')) }

  class << self
    def fetch_all(options)
      country_ids = options['country_ids']    if options.present? && options['country_ids'].present?

      operators = includes(:country, :users)
      operators = operators.filter_by_country_ids(country_ids)    if country_ids.present?
      operators
    end

    def operator_select
      by_name_asc.map { |c| [c.name, c.id] }
    end

    def types
      %w(Logging\ Company Artisanal Sawmill CommunityForest ARB1327 PalmOil Trader Company).freeze
    end

    def translated_types
      types.map { |t| [I18n.t("operator_types.#{t}", default: t), t.camelize] }
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end

  private

  def create_operator_id
    if country_id.present?
      update_columns(operator_id: "#{country.iso}-unknown-#{id}")
    else
      update_columns(operator_id: "na-unknown-#{id}")
    end
  end
end
