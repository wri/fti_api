# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_type :integer
#  name          :string
#

class Category < ApplicationRecord
  include Translatable
  enum :category_type, {operator: 0, government: 1}

  translates :name, touch: true
  active_admin_translates :name do
    validates :name, presence: true
  end

  has_many :subcategories, dependent: :destroy

  validates :name, presence: true

  scope :by_name_asc, -> { with_translations(I18n.locale).order("category_translations.name ASC") }

  ransacker(:name) { Arel.sql("category_translations.name") } # for nested_select in observation form

  def cache_key
    super + "-" + Globalize.locale.to_s
  end
end
