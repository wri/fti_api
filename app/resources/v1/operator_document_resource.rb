module V1
  class OperatorDocumentResource < JSONAPI::Resource
    caching
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :fmu_id, :current, :uploaded_by

    has_one :country
    has_one :fmu
    has_one :operator
    has_one :required_operator_document

    filters :type, :status, :operator_id, :current

    before_create :set_operator_id, :set_user_id

    # def fetchable_fields
    #   if (context[:current_user])
    #     super - [:attachment]
    #   else
    #     super
    #   end
    # end

    def set_operator_id
      if context[:current_user].present? && context[:current_user].operator_id.present?
        @model.operator_id = context[:current_user].operator_id
        @model.uplodaded_by = :operator
      end
    end

    def set_user_id
      if context[:current_user].present?
        @model.user_id = context[:current_user].id
      end
    end

#    def self.updatable_fields(context)
#      super - [:operator_id, :required_operator_document_id, :fmu_id]
#    end

#    def self.creatable_fields(context)
#      if (context[:current_user].present? && context[:current_user].user_permission.user_role != 'admin')
#       super - [:operator_id]
#      else
#        super
#      end
#    end


    def custom_links(_)
      { self: nil }
    end

  end
end
