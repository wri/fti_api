# frozen_string_literal: true

module CacheableByLocale
  extend ActiveSupport::Concern

  module ClassMethods
    def attribute_caching_context(context)
      (super || {}).merge(locale: context[:locale])
    end
  end
end
