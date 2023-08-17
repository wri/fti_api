class Page < ApplicationRecord
  include Translatable
  translates :title, :body, touch: true

  active_admin_translates :title do
    validates :title, presence: true
  end

  active_admin_translates :body do; end

  validates :slug, presence: true, uniqueness: true

  class << self
    def available_locales_for(page_slug)
      {
        "terms" => [:en]
      }[page_slug] || I18n.available_locales
    end
  end
end
