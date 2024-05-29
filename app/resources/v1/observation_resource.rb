# frozen_string_literal: true

module V1
  class ObservationResource < BaseResource
    include CacheableByLocale
    # caching

    attributes :observation_type, :publication_date, :pv, :is_active,
      :details, :evidence_type, :evidence_on_report, :concern_opinion,
      :litigation_status, :location_accuracy, :lat, :lng, :country_id,
      :fmu_id, :location_information, :subcategory_id, :severity_id,
      :created_at, :updated_at, :actions_taken, :validation_status, :validation_status_id,
      :is_physical_place, :complete, :hidden, :admin_comment, :monitor_comment, :locale

    has_many :species
    has_many :observation_documents
    has_many :observers
    has_many :relevant_operators, class_name: "Operator"
    has_many :governments

    has_one :country
    has_one :subcategory
    has_one :severity
    has_one :user
    has_one :modified_user, class_name: "User"

    has_one :operator
    has_one :law
    has_one :fmu
    has_one :observation_report

    before_create :set_user
    before_create :set_locale
    before_save :set_modified
    before_save :validate_status

    filters :id, :observation_type, :fmu_id, :country_id,
      :publication_date, :observer_id, :subcategory_id, :years,
      :observation_report, :law, :operator, :subcategory,
      :is_active, :validation_status, :is_physical_place

    filter :hidden, default: "false", apply: ->(records, value, options) {
      return records if value.include?("all")

      records.where(hidden: value)
    }

    filter :category_id, apply: ->(records, value, _options) {
      records.by_category(value)
    }

    filter :severity_level, apply: ->(records, value, _options) {
      records.by_severity_level(value)
    }

    filter :government_id, apply: ->(records, value, _options) {
      records.by_government(value)
    }

    filter :years, apply: ->(records, value, _options) {
      years = value.map(&:to_i).compact.reject(&:zero?).join(", ")
      records.joins(:observation_report).where("extract(year from observation_reports.publication_date) in (#{years})")
    }

    filter :"observation_report.id", apply: ->(records, value, _options) {
      records.joins(:observation_report).where(observation_reports: {id: value})
    }

    filter :observer_id, apply: ->(records, value, _options) {
      records.where(id: records.joins(:observers).where(observers: {id: value}).pluck(:id))
    }

    def fetchable_fields
      return super if observations_tool_user?

      super - [:admin_comment, :monitor_comment, :created_at, :updated_at, :user, :modified_user]
    end

    def self.sortable_fields(context)
      super + [:"country.iso", :"severity.level", :"subcategory.name",
        :"operator.name", :"country.name", :"law.written_infraction",
        :"fmu.name", :"observation_report.title", :"governments.government_entity", :"subcategory.category.name"]
    end

    def self.apply_sort(records, order_options, context = {})
      if order_options.key?("subcategory.category.name")
        records = records.order_by_category(order_options["subcategory.category.name"])
        order_options.except!("subcategory.category.name")
      end
      super(records, order_options, context)
    end

    def self.apply_includes(records, directives)
      super.includes(:observation_report, :observation_documents, :translations)
    end

    # An observation is complete if it has evidence
    def complete
      return true if @model.observation_documents.any?
      if @model.evidence_type == "Evidence presented in the report" &&
          @model.evidence_on_report && @model.observation_report_id
        return true
      end

      false
    end

    def validation_status_id
      Observation.validation_statuses[@model.validation_status]
    end

    def self.updatable_fields(context)
      super - [:hidden, :publication_date]
    end

    def self.creatable_fields(context)
      super - [:hidden, :publication_date]
    end

    def set_user
      @model.user_id = context[:current_user].id
    end

    def set_locale
      @model.locale = context[:current_user].locale if @model.locale.blank?
    end

    # Saves the last user who modified the observation and its locale
    def set_modified
      user = context[:current_user]
      @model.modified_user_id = user.id
      @model.force_translations_from = user.locale
    end

    # Makes sure the validation status can be an acceptable one
    def validate_status
      @model.validation_status = "Created" unless @model.persisted? || @model.validation_status == "Ready for QC"
      @model.user_type = :monitor
    end

    # To allow the filtering of results according to the app and user
    # In the portal, only the approved observations should be shown
    # (using the default scope)
    # In the observation tools, the monitors should see theirs

    def self.records(options = {})
      context = options[:context]
      user = context[:current_user]
      app = context[:app]

      if app == "observations-tool" && user.present?
        if user.user_permission.present? && user.user_permission.user_role == "admin"
          Observation.all
        elsif user.all_managed_observer_ids.any?
          Observation.own_with_inactive(user.all_managed_observer_ids)
        end
      else
        Observation.published
      end
    end
  end
end
