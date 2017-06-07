# frozen_string_literal: true
# == Schema Information
#
# Table name: fmus
#
#  id          :integer          not null, primary key
#  country_id  :integer
#  operator_id :integer
#  geojson     :json
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#


class Fmu < ApplicationRecord
  translates :name

  belongs_to :country, inverse_of: :fmus
  belongs_to :operator, inverse_of: :fmus
  has_many :documents, as: :attacheable, dependent: :destroy

  accepts_nested_attributes_for :documents, allow_destroy: true

  validates :country_id, presence: true

  default_scope { includes(:translations) }

  scope :filter_by_country, ->(country_id) { where(country_id: country_id) }

  class << self
    def fetch_all(options)
      country_id  = options['country'] if options.present? && options['country'].present?

      fmus = includes(:country)
      fmus = fmus.filter_by_country(country_id) if country_id.present?
      fmus
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end
