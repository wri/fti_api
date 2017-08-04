module V1
  class OperatorDocumentFmuResource < JSONAPI::Resource
    caching
    attributes :expire_date, :start_date,
               :status, :created_at, :updated_at,
               :attachment, :operator_id, :required_operator_document_id,
               :fmu_id, :current

    has_one :country
    has_one :fmu
    has_one   :operator
    has_one :required_operator_document
    has_one :required_operator_document_fmu
    has_many :documents

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
      if context[:current_user].present? && context[:current_user].operator_id.present?
        @model.operator_id = context[:current_user].operator_id
      end
    end

#    def self.updatable_fields(context)
#      super - [:operator_id, :required_operator_document_id, :fmu_id]
#    end


    def custom_links(_)
      { self: nil }
    end
  end
end