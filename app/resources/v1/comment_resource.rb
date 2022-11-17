# frozen_string_literal: true

module V1
  class CommentResource < BaseResource
    caching

    attributes :body
  end
end
