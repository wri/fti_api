# frozen_string_literal: true

# == Schema Information
#
# Table name: governments
#
#  id                :integer          not null, primary key
#  country_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default(TRUE), not null
#  government_entity :string
#  details           :text
#

class Government < ApplicationRecord
  has_paper_trail
  include Translatable

  translates :government_entity, :details, touch: true, versioning: :paper_trail

  # rubocop:disable Standard/BlockSingleLineBraces
  active_admin_translates :government_entity, :details do; end
  # rubocop:enable Standard/BlockSingleLineBraces

  belongs_to :country, inverse_of: :governments, optional: true

  has_many :governments_observations, dependent: :restrict_with_error
  has_many :observations, through: :governments_observations

  validates :government_entity, presence: true
  # TODO: change unique validation to not only on create, after cleaning up the data
  validates :government_entity, uniqueness: {case_sensitive: false}, on: :create

  scope :by_entity_asc, -> {
    with_translations(I18n.locale).order("government_translations.government_entity ASC")
  }

  scope :filter_by_country, ->(country_id) { where(country_id: country_id) }
  scope :active, -> { where(is_active: true) }

  default_scope { includes(:translations) }

  alias_method :to_s, :government_entity

  def cache_key
    super + "-" + Globalize.locale.to_s
  end
end
