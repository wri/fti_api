module V1
  class OperatorDocumentResource < JSONAPI::Resource
    caching
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :fmu_id, :current

    has_one :country
    has_one :fmu
    has_one :operator
    has_one :required_operator_document

    filters :type, :status

    before_create :set_operator_id

    def fetchable_fields
      if (context[:current_user])
        super - [:attachment]
      else
        super
      end
    end

    def set_operator_id
      # TODO: put the code from the controller here
      # @model.user_id ||= context[:current_user].id
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
