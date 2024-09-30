# frozen_string_literal: true

# == Schema Information
#
# Table name: subcategories
#
#  id                :integer          not null, primary key
#  category_id       :integer
#  subcategory_type  :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  location_required :boolean          default(TRUE), not null
#  name              :text
#  details           :text
#

class Subcategory < ApplicationRecord
  include Translatable
  enum :subcategory_type, {operator: 0, government: 1}
  translates :name, :details, touch: true

  # rubocop:disable Standard/BlockSingleLineBraces
  active_admin_translates :name do; end
  # rubocop:enable Standard/BlockSingleLineBraces

  validates :subcategory_type, presence: true

  belongs_to :category
  has_many :severities, dependent: :destroy
  has_many :observations, inverse_of: :subcategory, dependent: :destroy
  has_many :laws, inverse_of: :subcategory

  scope :by_name_asc, -> { with_translations(I18n.locale).order("subcategory_translations.name ASC") }

  ransacker(:name) { Arel.sql("subcategory_translations.name") } # for nested_select in observation form
end
