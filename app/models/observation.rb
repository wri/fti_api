# frozen_string_literal: true
# == Schema Information
#
# Table name: observations
#
#  id               :integer          not null, primary key
#  severity_id      :integer
#  observation_type :integer          not null
#  user_id          :integer
#  publication_date :datetime
#  country_id       :integer
#  observer_id      :integer
#  operator_id      :integer
#  government_id    :integer
#  pv               :string
#  is_active        :boolean          default(TRUE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  lat              :decimal(, )
#  lng              :decimal(, )
#  fmu_id           :integer
#  subcategory_id   :integer
#

class Observation < ApplicationRecord
  include ValidationHelper
  translates :details, :evidence, :concern_opinion, :litigation_status

  enum observation_type: %w(operator government)

  belongs_to :country,    inverse_of: :observations
  belongs_to :observer,   inverse_of: :observations, optional: true
  belongs_to :severity,   inverse_of: :observations
  belongs_to :operator,   inverse_of: :observations, optional: true
  belongs_to :government, inverse_of: :observations, optional: true
  belongs_to :user,       inverse_of: :observations, optional: true
  belongs_to :fmu,        inverse_of: :observations, optional: true

  belongs_to :subcategory, inverse_of: :observations, optional: true

  has_many :species_observations
  has_many :species, through: :species_observations

  has_many :comments,  as: :commentable
  has_many :photos,    as: :attacheable, dependent: :destroy
  has_many :documents, as: :attacheable, dependent: :destroy

  accepts_nested_attributes_for :photos,           allow_destroy: true
  accepts_nested_attributes_for :documents,        allow_destroy: true
  accepts_nested_attributes_for :subcategory, allow_destroy: false


  validates :country_id,       presence: true
  validates :publication_date, presence: true

  include Activable


  default_scope { includes(:translations) }

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
end
