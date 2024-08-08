# frozen_string_literal: true

module V1
  class ObservationResource < BaseResource
    include CacheableByLocale
    # TODO: investigate caching issues, I remember it was somthing with included resources like observers
    # caching

    attributes :observation_type, :publication_date, :pv, :is_active,
      :details, :evidence_type, :evidence_on_report, :concern_opinion,
      :litigation_status, :location_accuracy, :lat, :lng, :country_id,
      :fmu_id, :location_information, :subcategory_id, :severity_id,
      :created_at, :updated_at, :actions_taken, :validation_status, :validation_status_id,
      :is_physical_place, :complete, :hidden, :user_type, :qc1_comment, :qc2_comment, :monitor_comment, :locale

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

    before_create :set_locale
    before_save :set_user
    before_update :set_qc_validation_status

    filters :id, :observation_type, :fmu_id, :country_id,
      :publication_date, :observer_id, :subcategory_id, :years,
      :observation_report, :law, :operator, :subcategory, :validation_status,
      :is_active, :is_physical_place

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

      super - [:qc1_comment, :qc2_comment, :monitor_comment, :created_at, :updated_at, :user, :modified_user]
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

    def set_locale
      @model.locale = context[:current_user].locale if @model.locale.blank?
    end

    def set_user
      user = context[:current_user]
      @model.user_type = :monitor if @model.user_type.blank?
      @model.user_id = user.id if context[:action] == "create"
      @model.modified_user_id = user.id
      @model.force_translations_from = @model.locale || user.locale
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

    private

    def set_qc_validation_status
      return if qc_action.blank?

      ready_for_review_action if qc_action == "ready_for_review"
      start_qc_action if qc_action == "start_qc"
      approve_qc_action if qc_action == "approve_qc"
      reject_qc_action if qc_action == "reject_qc"
    end

    def ready_for_review_action
      @model.validation_status = if @model.published? || @model.validation_status == "Needs revision"
        "Ready for QC2"
      else
        @model.qc1_needed? ? "Ready for QC1" : "Ready for QC2"
      end
    end

    def start_qc_action
      @model.user_type = :reviewer
      @model.validation_status = "QC1 in progress" if @model.validation_status == "Ready for QC1"
      @model.validation_status = "QC2 in progress" if @model.validation_status == "Ready for QC2"
    end

    def approve_qc_action
      @model.user_type = :reviewer
      @model.validation_status = "Ready for QC2" if @model.validation_status == "QC1 in progress"
      @model.validation_status = "Ready for publication" if @model.validation_status == "QC2 in progress"
    end

    def reject_qc_action
      @model.user_type = :reviewer
      @model.validation_status = "Rejected" if @model.validation_status == "QC1 in progress"
      @model.validation_status = "Needs revision" if @model.validation_status == "QC2 in progress"
    end

    def qc_action
      context[:custom_command]
    end
  end
end
