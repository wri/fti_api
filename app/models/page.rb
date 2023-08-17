class Page < ApplicationRecord
  include Translatable
  translates :title, :body, touch: true

  active_admin_translates :title do
    validates :title, presence: true
  end

  active_admin_translates :body do; end

  validates :slug, presence: true, uniqueness: true

  before_validation :fix_blank_available_in_languages

  private

  def fix_blank_available_in_languages
    available_in_languages&.reject!(&:blank?)
    self.available_in_languages = nil if available_in_languages.blank?
  end
end
