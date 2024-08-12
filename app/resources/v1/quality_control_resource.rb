# frozen_string_literal: true

module V1
  class QualityControlResource < BaseResource
    include CacheableByLocale
    caching

    has_one :reviewable, polymorphic: true, always_include_linkage_data: true

    attributes :comment, :passed, :created_at, :updated_at

    before_create :set_reviewer

    def set_reviewer
      @model.reviewer = context[:current_user]
    end
  end
end
