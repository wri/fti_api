# frozen_string_literal: true

module V1
  class OperatorResource < BaseResource
    include CacheableByLocale

    caching
    attributes :name, :approved, :operator_type, :concession, :is_active, :logo,
      :details, :percentage_valid_documents_fmu, :percentage_valid_documents_country,
      :percentage_valid_documents_all, :obs_per_visit, :score,
      :website, :address, :fa_id, :country_doc_rank, :country_operators,
      :delete_logo, :email

    has_one :country
    has_many :fmus
    has_many :users
    has_many :observations
    has_many :sawmills

    has_many :operator_documents
    has_many :operator_document_fmus
    has_many :operator_document_countries

    has_many :operator_document_histories
    has_many :operator_document_country_histories
    has_many :operator_document_fmu_histories

    filters :country, :is_active, :name, :operator_type, :fa
    filters :is_active, :name, :operator_type, :fa

    before_create :set_active
    after_create :send_notification

    def type
      @model.type
    end

    def set_active
      @model.is_active = false
    end

    def name
      I18n.with_locale(:en) { @model.name }
    end

    filter :certification, apply: ->(records, value, _options) {
      values = value.select { |c| %w[fsc pefc olb pafc fsc_cw tlv ls].include? c }
      return records unless values.any?

      certifications = []
      values.each do |v|
        certifications << "fmus.certification_#{v} = true"
      end
      records = records.joins(:fmus).where(certifications.join(" OR ")).distinct

      records
    }

    filter :observer_id, apply: ->(records, value, _options) {
      records.where(
        id: Observation.own_with_inactive(value[0].to_i).select(:operator_id).distinct.select(:operator_id)
      )
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
      super + [:"country.name"]
    end

    filter :"country.name", apply: ->(records, value, _options) {
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

    def percentage_valid_documents_all
      @model.score_operator_document&.all
    end

    def percentage_valid_documents_fmu
      @model.score_operator_document&.fmu
    end

    def percentage_valid_documents_country
      @model.score_operator_document&.country
    end

    def obs_per_visit
      @model.score_operator_observation&.obs_per_visit
    end

    def score
      @model.score_operator_observation&.score
    end

    def self.apply_includes(records, directives)
      super.includes(:score_operator_document, :score_operator_observation) if super.present?
    end

    def self.records(options = {})
      context = options[:context]
      user = context[:current_user]
      app = context[:app]
      controller = context[:controller]

      # not great to filter by controller here, but not sure how to do it in observation resource only
      if (app == "observations-tool" && user.present?) || controller == "v1/observations"
        super(options)
      else
        Operator.active
      end
    end

    private

    def send_notification
      SystemMailer.operator_created(@model).deliver_later
    end
  end
end
