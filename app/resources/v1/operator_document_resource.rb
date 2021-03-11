# frozen_string_literal: true

module V1
  class OperatorDocumentResource < JSONAPI::Resource
    include CacheableByLocale
    include CacheableByCurrentUser
    include OperatorDocumentable
    caching

    before_update :set_source, :set_public, :set_operator_id, :set_user_id, :set_status_pending

    def set_operator_id
      if context[:current_user].present? && context[:current_user].operator_id.present?
        @model.operator_id = context[:current_user].operator_id
        @model.uploaded_by = :operator
      end
    end

    def set_public
      @model.public = false
    end

    def set_source
      @model.source = OperatorDocument.sources[:company]
    end

    def set_status_pending
      @model.status = :doc_pending
    end

    def self.updatable_fields(context)
      super - [:note, :response_date, :source]
    end
    def self.creatable_fields(context)
      super - [:note, :response_date, :source]
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
      end
    end

    def status
      return @model.status if can_see_document?

      hidden_document_status
    end

    def self.records(options = {})
      OperatorDocument.from_active_operators
    end

    def custom_links(_)
      { self: nil }
    end
  end
end
