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

  scope :by_date_desc,  ->           { order('observations.publication_date DESC') }
  scope :by_user_ids,   ->(by_users) { where(user_id: [by_users])                     }

  scope :filter_by_country_ids,   ->(country_ids)     { where(country_id: country_ids.split(',')) }
  scope :filter_by_fmu_ids,       ->(fmu_ids)         { where(fmu_id: fmu_ids.split(',')) }
  scope :filter_by_years,         ->(years)           { where("extract(year from publication_date) in (#{years})") }
  scope :filter_by_observer_ids,  ->(observer_ids)    { where(observer_id: observer_ids.split(',')) }
  #scope :filter_by_category_ids,  ->(category_ids)    { joins(annex_operator: :categorings).where('annex_operator') }
  scope :filter_by_severities,    ->(severity_levels) { joins(:severity).where("severities.level in (#{severity_levels})") }

  default_scope { includes(:translations) }

  class << self
    def fetch_all(options)
      by_user_ids    = options['user_ids']    if options.present? && options['user_ids'].present? && ValidationHelper.ids?(options['user_ids'])
      by_type    = options['type']            if options.present? && options['type'].present?
      country_ids = options['country_ids']    if options.present? && options['country_ids'].present? && ValidationHelper.ids?(options['country_ids'])
      fmu_ids = options['fmu_ids']            if options.present? && options['fmu_ids'].present? && ValidationHelper.ids?(options['fmu_ids'])
      years = options['years']                if options.present? && options['years'].present? && ValidationHelper.ids?(options['years'])
      observer_ids = options['observer_ids']  if options.present? && options['observer_ids'].present? && ValidationHelper.ids?(options['observer_ids'])
      #category_id = options['category_id']    if options.present? && options['category_id'].present?
      severities = options['severities']        if options.present? && options['severities'].present? && ValidationHelper.ids?(options['severities'])


      observations = includes([:documents, :photos,
                               :country, :species, :observer, :operator,
                               :severity, :comments, :government,
                               { annex_operator: :translations },
                               { annex_governance: :translations }])

      observations = observations.by_user_ids(by_user_ids)              if by_user_ids.present?
      observations = observations.filter_by_country_ids(country_ids)    if country_ids.present?
      observations = observations.filter_by_fmus(fmu_ids)               if fmu_ids.present?
      observations = observations.filter_by_years(years)                if years.present?
      observations = observations.filter_by_observer_ids(observer_ids)  if observer_ids.present?
      #observations = observations.filter_by_category(category_id)       if category_id.present?
      observations = observations.filter_by_severities(severities)      if severities.present?
      observations
    end

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
