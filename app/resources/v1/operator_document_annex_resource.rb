# frozen_string_literal: true

module V1
  class OperatorDocumentAnnexResource < BaseResource
    include CacheableByLocale
    include CacheableByCurrentUser
    include Privateable

    caching
    attributes :name,
      :start_date, :expire_date, :status, :attachment,
      :uploaded_by, :created_at, :updated_at

    privateable :show_attributes?, [:name, :start_date, :expire_date, :status, :attachment, :uploaded_by, :created_at, :updated_at]

    has_one :operator_document, foreign_key_on: :related

    filters :status

    before_create :set_user_id, :set_status, :set_public

    def operator_document_id=(operator_document_id)
      od = OperatorDocument.find operator_document_id
      ad = AnnexDocument.new(documentable: od)
      @model.annex_document = ad

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

    def set_public
      @model.public = false
    end

    def set_status
      @model.status = OperatorDocumentAnnex.statuses[:doc_pending]
    end

    def show_attributes?
      @model.status == "doc_valid" || belongs_to_user?
    end

    private

    # TODO: Refactor this
    def belongs_to_user?
      user = context[:current_user]
      return true if user&.user_permission&.user_role == "admin"

      annex_document_id =
        AnnexDocument.find_by(documentable_type: "OperatorDocument",
          operator_document_annex_id: @model.id)&.documentable_id
      operator_id = OperatorDocument.find_by(id: annex_document_id)&.operator_id

      user&.is_operator?(operator_id)
    end
  end
end
