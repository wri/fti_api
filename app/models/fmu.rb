# frozen_string_literal: true
# == Schema Information
#
# Table name: fmus
#
#  id                 :integer          not null, primary key
#  country_id         :integer
#  operator_id        :integer
#  geojson            :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  certification_fsc  :boolean          default(FALSE)
#  certification_pefc :boolean          default(FALSE)
#  certification_olb  :boolean          default(FALSE)
#

class Fmu < ApplicationRecord
  include ValidationHelper
  translates :name

  active_admin_translates :name do
    validates_presence_of :name
  end

  belongs_to :country, inverse_of: :fmus
  belongs_to :operator, inverse_of: :fmus
  has_many :observations, inverse_of: :fmu

  validates :country_id, presence: true
  validates :name, presence: true

  default_scope { includes(:translations) }

  scope :filter_by_countries,  ->(country_ids)  { where(country_id: country_ids.split(',')) }
  scope :filter_by_operators,  ->(operator_ids) { where(operator_id: operator_ids.split(',')) }
  scope :filter_by_free,       ->()             { where operator_id: nil}

  class << self
    def fetch_all(options)
      country_ids  = options['country_ids'] if options.present? && options['country_ids'].present? && ValidationHelper.ids?(options['country_ids'])
      operator_ids  = options['operator_ids'] if options.present? && options['operator_ids'].present? && ValidationHelper.ids?(options['operator_ids'])
      free = options.present? && options['free'] == 'true'

      fmus = includes([:country, :operator])
      fmus = fmus.filter_by_countries(country_ids) if country_ids.present?
      fmus = fmus.filter_by_operators(operator_ids) if operator_ids.present?
      fmus = fmus.filter_by_free if free
      fmus
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end
