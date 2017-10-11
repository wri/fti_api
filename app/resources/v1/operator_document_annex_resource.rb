module V1
  class OperatorDocumentAnnexResource < JSONAPI::Resource
    caching
    attributes :operator_document_id, :name,
               :start_date, :expire_date, :status,
               :uploaded_by, :created_at, :updated_at

    has_one :operator_document

    filters :status, :operator_document_id

    before_create :set_user_id

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
      end
    end

    def custom_links(_)
      { self: nil }
    end

  end
end
