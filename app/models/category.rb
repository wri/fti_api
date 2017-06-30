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
  enum category_type: { operator: 0, government: 1 }

  translates :name

  has_many :subcategories, dependent: :destroy

  validates :name, presence: true
  validate :uniqueness

  scope :by_name_asc, -> {
    includes(:translations).with_translations(I18n.available_locales)
                           .order('category_translations.name ASC')
  }

  default_scope do
    includes(:translations)
  end

  class << self
    def fetch_all(options)
      categories = includes({ subcategories: :translations })
      categories
    end
  end

  def cache_key
    super + '-' + Globalize.locale.to_s
  end

  private

  def uniqueness
    if Category.where(name: self.name, category_type: self.category_type).any?
      self.errors[:name] = 'Must be unique'
    end
  end
end
