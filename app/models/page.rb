class Page < ApplicationRecord
  include Translatable
  translates :title, :body, touch: true

  active_admin_translates :title do
    validates :title, presence: true
  end

  active_admin_translates :body do; end

  validates :slug, presence: true, uniqueness: true
end
