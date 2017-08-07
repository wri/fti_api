module V1
  class OperatorResource < JSONAPI::Resource
    caching
    attributes :name, :operator_type, :concession, :is_active, :logo, :details,
               :percentage_valid_documents_fmu, :percentage_valid_documents_country,
               :percentage_valid_documents_all, :certification, :score, :observations_per_visit

    has_one :country
    has_many :fmus
    has_many :users
    has_many :observations

    has_many :operator_documents
    has_many :operator_document_fmus
    has_many :operator_document_countries

    filters :country, :is_active, :name, :operator_type

    def self.updatable_fields(context)
      super - [:score, :observations_per_visit,
               :percentage_valid_documents_fmu, :percentage_valid_documents_country, :percentage_valid_documents_all]
    end
    def self.creatable_fields(context)
      super - [:score, :observations_per_visit,
               :percentage_valid_documents_fmu, :percentage_valid_documents_country, :percentage_valid_documents_all]
    end

    def custom_links(_)
      { self: nil }
    end
  end
end
