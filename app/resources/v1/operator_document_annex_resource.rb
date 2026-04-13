# frozen_string_literal: true

module V1
  class OperatorDocumentAnnexResource < BaseResource
    include CacheableByLocale
    include CacheableByCurrentUser
    include Privateable

    caching
    attributes :name,
      :start_date, :expire_date, :status, :invalidation_reason, :attachment,
      :uploaded_by, :created_at, :updated_at

    privateable :show_attributes?, [:name, :invalidation_reason, :start_date, :expire_date, :status, :attachment, :uploaded_by, :created_at, :updated_at]

    has_one :operator_document, foreign_key_on: :related

    filters :status

    after_replace_fields :update_status_if_any_changes
    before_create :set_user_id, :set_status_pending, :set_public

    def self.updatable_fields(context)
      [:name, :start_date, :expire_date, :attachment]
    end

    def self.creatable_fields(context)
      updatable_fields(context) + [:operator_document]
    end

    def operator_document_id=(operator_document_id)
      od = OperatorDocument.find operator_document_id
      @model.operator_document = od # this will also set @model.annex_document

      odh = OperatorDocumentHistory.where(operator_document_id: operator_document_id).order(operator_document_updated_at: :desc).first
      adh = AnnexDocument.new(documentable: odh)
      @model.annex_documents_history << adh
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
        @model.uploaded_by = :operator
      end
    end

    def update_status_if_any_changes
      return unless @model.changed?

      set_status_pending
      set_user_id
    end

    def set_public
      @model.public = false
    end

    def set_status_pending
      @model.status = :doc_pending
    end

    def show_attributes?
      @model.doc_valid? || @model.doc_expired? || belongs_to_user?
    end

    def self.records(options = {})
      context = options[:context]
      user = context[:current_user]

      if user.present?
        return OperatorDocumentAnnex.all if user.admin?
        return OperatorDocumentAnnex.from_operator(user.operator_ids) if user.operator_ids.any?
      end

      OperatorDocumentAnnex.where(status: [:doc_valid, :doc_expired])
    end

    private

    def belongs_to_user?
      user = context[:current_user]
      return false if user.blank?
      return true if user.admin?

      user.is_operator?(@model.operator&.id)
    end
  end
end
