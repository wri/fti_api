# frozen_string_literal: true

module V1
  class OperatorResource < JSONAPI::Resource
    include CacheableByLocale
    caching
    attributes :name, :approved, :operator_type, :concession, :is_active, :logo,
               :details, :percentage_valid_documents_fmu, :percentage_valid_documents_country,
               :percentage_valid_documents_all, :score, :obs_per_visit,
               :website, :address, :fa_id, :country_doc_rank, :country_operators,
               :delete_logo

    has_one :country
    has_many :fmus
    has_many :users
    has_many :observations
    has_many :sawmills

    has_many :operator_documents
    has_many :operator_document_fmus
    has_many :operator_document_countries

    filters :country, :is_active, :name, :operator_type, :fa

    before_create :set_active

    def set_active
      @model.is_active = false
    end

    filter :certification, apply: ->(records, value, _options) {
      records = records.fmus_with_certification_fsc       if value.include?('fsc')
      records = records.fmus_with_certification_pefc      if value.include?('pefc')
      records = records.fmus_with_certification_olb       if value.include?('olb')

      records
    }

    def fetchable_fields
      super - [:delete_logo]
    end

    def self.updatable_fields(context)
      super - [:score, :obs_per_visit, :fa_id,
               :percentage_valid_documents_fmu, :percentage_valid_documents_country, :percentage_valid_documents_all,
               :country_doc_rank, :country_operators]
    end

    def self.creatable_fields(context)
      super - [:score, :obs_per_visit, :fa_id,
               :percentage_valid_documents_fmu, :percentage_valid_documents_country, :percentage_valid_documents_all,
               :country_doc_rank, :country_operators]
    end

    def self.sortable_fields(context)
      super + [:'country.name']
    end

    filter :'country.name', apply: ->(records, value, _options) {
      if value.present?
        sanitized_value = ActiveRecord::Base.connection.quote("%#{value[0].downcase}%")
        records.joins(:country).joins([country: :translations]).where("lower(country_translations.name) like #{sanitized_value}")
      else
        records
      end
    }

    filter :fa, apply: ->(records, _value, _options) {
      records.fa_operator
    }

    def obs_per_visit
      sprintf('%<two_decimals>.2f', @model.obs_per_visit) if @model.obs_per_visit.present?
    end

    def self.records(options = {})
      context = options[:context]
      user = context[:current_user]
      app = context[:app]
      if app == 'observations-tool' && user.present?
        super(options)
      else
        Operator.active
      end
    end

    def custom_links(_)
      { self: nil }
    end
  end
end
