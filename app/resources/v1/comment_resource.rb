# frozen_string_literal: true

module V1
  class CommentResource < JSONAPI::Resource
    caching

    attributes :body

    def custom_links(_)
      { self: nil }
    end
  end
end
