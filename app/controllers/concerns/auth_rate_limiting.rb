# frozen_string_literal: true

# Shared 429 body and cache store for Rails' built-in `rate_limit`.
#
# Test/dev use an isolated MemoryStore so we don't depend on Rails.cache
# (null_store there, and JSONAPI resource caching also points at it).
# Production-like envs use Rails.cache so Puma workers on one host share
# the counters.
module AuthRateLimiting
  extend ActiveSupport::Concern

  STORE = if Rails.env.local?
    ActiveSupport::Cache::MemoryStore.new
  else
    Rails.cache
  end

  TOO_MANY_REQUESTS = {errors: [{status: 429, title: "Too many requests"}]}.freeze

  private

  def render_too_many_requests
    render json: TOO_MANY_REQUESTS, status: :too_many_requests
  end
end
