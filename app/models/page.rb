# == Schema Information
#
# Table name: pages
#
#  id                     :bigint           not null, primary key
#  slug                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  available_in_languages :string           is an Array
#  title                  :string
#  body                   :text
#
class Page < ApplicationRecord
  include Translatable
  translates :title, :body, touch: true

  active_admin_translates :title do
    validates :title, presence: true
  end

  # rubocop:disable Standard/BlockSingleLineBraces
  active_admin_translates :body do; end
  # rubocop:enable Standard/BlockSingleLineBraces

  validates :slug, presence: true, uniqueness: true

  before_validation :fix_blank_available_in_languages

  private

  def fix_blank_available_in_languages
    available_in_languages&.reject!(&:blank?)
    self.available_in_languages = nil if available_in_languages.blank?
  end
end
