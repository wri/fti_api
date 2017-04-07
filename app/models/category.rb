# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Category < ApplicationRecord
  translates :name

  has_many :categorings, dependent: :destroy
  has_many :annex_governances, through: :categorings
  has_many :annex_operators,   through: :categorings

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :by_name_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
                           .order('category_translations.name ASC')
  }

  default_scope do
    includes(:translations, { annex_governances: :translations }, { annex_operators: :translations }).
    with_translations(I18n.available_locales)
  end

  class << self
    def fetch_all(options)
      categories = all
      categories
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end
end
