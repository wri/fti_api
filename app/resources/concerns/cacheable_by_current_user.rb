# frozen_string_literal: true

module CacheableByCurrentUser
  extend ActiveSupport::Concern

  module ClassMethods
    def attribute_caching_context(context)
      (super || {}).merge(owner: context[:current_user].id)
    end
  end
end
