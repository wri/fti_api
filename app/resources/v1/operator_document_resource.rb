# frozen_string_literal: true

module V1
  class OperatorDocumentResource < JSONAPI::Resource
    include CacheableByLocale
    include CacheableByCurrentUser
    caching
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :fmu_id, :current, :uploaded_by, :reason, :note, :response_date,
               :public, :source_info
    attribute  :source_type, delegate: :source

    has_one :country
    has_one :fmu
    has_one :operator
    has_one :required_operator_document
    has_many :operator_document_annexes

    filters :type, :status, :operator_id, :current

    before_create :set_public, :set_source
    before_update :set_operator_id, :set_user_id, :set_status_pending

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

    # TODO: Implement permissions system here
    def status
      return @model.status if can_see_document?

      # return :doc_not_provided unless document_public?

      hidden_document_status
    end

    def attachment
      return @model.attachment if can_see_document? || document_public?

      { url: nil }
    end

    def self.records(options = {})
      OperatorDocument.all
    end

    def custom_links(_)
      { self: nil }
    end

    def document_public?
      @model.public || @model.operator.approved
    end

    def can_see_document?
      user = @context[:current_user]
      app = @context[:app]

      return false if app == 'observations-tool'
      return true if user&.user_permission&.user_role =='admin'
      return true if user&.is_operator?(@model.operator_id)

      false
    end

    def hidden_document_status
      return @model.status if %w[doc_not_provided doc_valid doc_expired doc_not_required].include?(@model.status)

      :doc_not_provided
    end
  end
end
