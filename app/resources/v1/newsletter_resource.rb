# frozen_string_literal: true

module V1
  class NewsletterResource < BaseResource
    caching
    immutable

    attributes :title, :date, :short_description, :image, :attachment

    def self.default_sort
      [{field: :date, direction: :desc}]
    end
  end
end
