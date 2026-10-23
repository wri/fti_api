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
  # the portal links to these pages by slug
  PROTECTED_SLUGS = %w[about terms privacy-policy].freeze

  include Translatable
  translates :title, :body, touch: true

  active_admin_translates :title do
    validates :title, presence: true
  end

  # rubocop:disable Standard/BlockSingleLineBraces
  active_admin_translates :body do; end
  # rubocop:enable Standard/BlockSingleLineBraces

  has_many :sections, -> { order(:position) }, class_name: "PageSection", dependent: :destroy, inverse_of: :page

  validates :slug, presence: true, uniqueness: true
  validate :protected_slug_unchanged, on: :update

  before_validation :fix_blank_available_in_languages
  before_destroy :prevent_destroying_protected_page, prepend: true

  def protected?
    PROTECTED_SLUGS.include?(slug_was)
  end

  private

  def protected_slug_unchanged
    errors.add(:slug, :cannot_change_protected_slug) if slug_changed? && protected?
  end

  def prevent_destroying_protected_page
    return unless protected?

    errors.add(:base, :cannot_delete_protected_page)
    throw :abort
  end

  def fix_blank_available_in_languages
    available_in_languages&.reject!(&:blank?)
    self.available_in_languages = nil if available_in_languages.blank?
  end
end
