module V1
  class OperatorDocumentCountryResource < JSONAPI::Resource
    caching
    attributes :expire_date, :start_date, :status, :created_at, :updated_at, :attachment

    has_one :country
    has_one   :operator
    has_one :required_operator_document
    has_one :required_operator_document_country
    has_many :documents

    filters :type, :status

    def fetchable_fields
      if context[:current_user] &&
          (context[:current_user].user_permission.user_role == 'admin' || context[:current_user].operator_id == @model.operator_id)
        super
      else
        super - [:attachment]
      end
    end

#    def self.updatable_fields(context)
#      super - [:operator_id, :required_operator_document_id]
#    end

    def custom_links(_)
      { self: nil }
    end
  end
end
