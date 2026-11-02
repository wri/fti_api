# frozen_string_literal: true

class PageSection < ApplicationRecord
  # each code makes the portal render a component after the section text
  CODES = %w[partners donors documents tools faqs related_pages].freeze

  include Translatable
  translates :title, :body, touch: true

  # a section with a code may be just the component, without heading or text
  active_admin_translates :title, :body do
    validates :title, :body, presence: true, unless: -> { globalized_model&.code.present? }
  end

  belongs_to :page, touch: true
  acts_as_list scope: :page

  validates :code, inclusion: {in: CODES}, allow_nil: true

  normalizes :code, with: -> { it.presence }
end
