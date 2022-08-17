# frozen_string_literal: true

module ObsToolFilter
  extend ActiveSupport::Concern

  included do
    filter :obs_tool_filter, apply: ->(records, value, options) {
      context = options[:context]
      user = context[:current_user]
      app = context[:app]

      next records unless app == 'observations-tool'
      next records if user.blank?
      next records if user.observer_id.blank?

      obs_tool_filter_scope(records, user)
    }
  end

  class_methods do
    # to apply scope only for observation tool requests
    def obs_tool_filter_scope(records, user)
      raise NotImplementedError
    end
  end
end
