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

    def fetchable_fields
      if (context[:current_user])
        super - [:attachment]
      else
        super
      end
    end


    def custom_links(_)
      { self: nil }
    end

#    def self.updatable_fields(context)
#      super + [:operator_id]
#    end
  end
end
