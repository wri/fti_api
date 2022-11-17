# frozen_string_literal: true

module V1
  class GovFileResource < BaseResource
    include CacheableByLocale
    include CacheableByCurrentUser
    caching
    attributes :attachment, :gov_document_id

    has_one :gov_document
  end
end
