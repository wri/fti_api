# frozen_string_literal: true

ActiveAdmin.register Observation do
  extend BackRedirectable
  extend Versionable

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale).includes(
        [
          [country: :translations],
          [severity: :translations],
          [subcategory: [category: :translations]],
          :observers
        ]
      )
    end
  end

  active_admin_paranoia

  menu false

  per_page = [10, 20, 40, 60].freeze

  config.order_clause
  config.per_page = per_page
  config.sort_order = "updated_at_desc"

  before_action only: :index do
    if per_page.include? params[:per_page]
      @per_page = params[:per_page]
      session[:obs_per_page] = @per_page
    else
      session[:obs_per_page] = per_page.include?(session[:obs_per_page]) ? session[:obs_per_page] : 10
      @per_page = session[:obs_per_page]
    end
  end

  actions :all, except: [:new]

  permit_params :name, :lng, :pv, :lat, :lon, :subcategory_id, :severity_id, :country_id, :operator_id, :user_type,
    :validation_status, :publication_date, :observation_report_id, :location_information, :evidence_type,
    :evidence_on_report, :location_accuracy, :law_id, :fmu_id, :hidden, :non_concession_activity,
    :actions_taken, :is_physical_place, :force_translations_from,
    relevant_operator_ids: [], government_ids: [],
    observation_document_ids: [],
    translations_attributes: [:id, :locale, :details, :concern_opinion, :litigation_status, :_destroy]

  member_action :start_qc, method: [:put, :get] do
    if resource.update(user_type: :reviewer, validation_status: "QC2 in progress")
      redirect_to new_admin_quality_control_path(quality_control: {reviewable_id: resource.id, reviewable_type: "Observation"}), notice: I18n.t("active_admin.observations_page.moved_qc_in_progress")
    else
      redirect_to collection_path, notice: I18n.t("active_admin.observations_page.not_modified")
    end
  end

  member_action :force_translations do
    translate_from = params[:translate_from] || I18n.locale
    TranslationJob.perform_later(resource, translate_from)
    redirect_to admin_observation_path(resource), notice: I18n.t("active_admin.shared.translating_entity")
  end

  action_item :force_translations, only: :show do
    dropdown_menu I18n.t("active_admin.shared.force_translations") do
      I18n.available_locales.sort.each do |locale|
        item locale, force_translations_admin_observation_path(observation, translate_from: locale)
      end
    end
  end

  action_item :start_qc, only: :show, if: proc { resource.validation_status == "Ready for QC2" && resource.responsible_for_qc2.include?(current_user) } do
    link_to I18n.t("active_admin.shared.start_qc"), start_qc_admin_observation_path(observation), method: :put
  end

  # Bulk actions should be available only if this env flag is set to `true`
  if ENV.fetch("BULK_EDIT_OBSERVATIONS", "TRUE").upcase == "TRUE"
    batch_action :hide, confirm: I18n.t("active_admin.observations_page.bulk_hide") do |ids|
      batch_action_collection.find(ids).each do |observation|
        observation.update(hidden: true)
      end
      redirect_to collection_path, notice: I18n.t("active_admin.observations_page.hidden")
    end

    batch_action :unhide, confirm: I18n.t("active_admin.observations_page.bulk_unhide") do |ids|
      batch_action_collection.find(ids).each do |observation|
        observation.update(hidden: false)
      end
      redirect_to collection_path, notice: I18n.t("active_admin.observations_page.unhidden")
    end
  end

  sidebar I18n.t("active_admin.operator_page.documents"), only: [:show] do
    attributes_table_for resource do
      ul do
        resource.observation_documents.collect do |od|
          li link_to(od.name, admin_evidence_path(od.id))
        end
      end
    end
  end

  scope -> { I18n.t("active_admin.all") }, :all, default: true
  scope -> { I18n.t("activerecord.models.operator") }, :operator
  scope -> { I18n.t("activerecord.models.government") }, :government
  scope -> { I18n.t("active_admin.operator_documents_page.pending") }, :pending
  scope -> { I18n.t("active_admin.observations_dashboard_page.published_all") }, :published
  scope -> { I18n.t("shared.created") }, :created
  scope -> { I18n.t("active_admin.observations_page.scope_hidden") }, :hidden
  scope -> { I18n.t("active_admin.observations_page.visible") }, :visible

  # region filters
  filter :id, as: :numeric_range_filter
  filter :validation_status,
    as: :select,
    input_html: {multiple: true},
    collection: -> { Observation.validation_statuses.sort }
  filter :country, as: :select, collection: -> { Country.with_observations.by_name_asc }
  filter :operator, as: :select, collection: -> { Operator.by_name_asc }
  filter :fmu, as: :select, collection: -> { Fmu.by_name_asc }
  filter :governments, as: :select, label: -> { Government.human_attribute_name(:government_entity) }, collection: -> { Government.by_entity_asc }
  filter :subcategory_category_id, label: -> { I18n.t("activerecord.models.category") }, as: :select, collection: -> { Category.by_name_asc }
  filter :subcategory, as: :select, label: -> { I18n.t("activerecord.models.subcategory") }, collection: -> { Subcategory.by_name_asc }
  filter :severity_level, as: :select, collection: [["Unknown", 0], ["Low", 1], ["Medium", 2], ["High", 3]]
  filter :observers, as: :select, label: -> { I18n.t("activerecord.models.observer") }, collection: -> { Observer.by_name_asc }
  filter :observation_report,
    label: -> { I18n.t("activerecord.models.observation_report") }, as: :select,
    collection: -> { ObservationReport.order(:title) }
  filter :user, label: -> { I18n.t("active_admin.observations_page.created_user") }, as: :select, collection: -> { User.order(:name) }
  filter :modified_user, label: -> { I18n.t("active_admin.observations_page.modified_user") }, as: :select, collection: -> { User.order(:name) }
  filter :is_active
  filter :publication_date
  filter :updated_at
  filter :deleted_at
  # endregion

  dependent_filters do
    {
      country_id: {
        operator_id: Operator.pluck(:country_id, :id),
        fmu_id: Fmu.pluck(:country_id, :id),
        government_ids: Government.pluck(:country_id, :id),
        observer_ids: Observer.joins(:countries).pluck(:country_id, :id)
      },
      subcategory_category_id: {
        subcategory_id: Subcategory.pluck(:category_id, :id)
      },
      observer_ids: {
        observation_report_id: ObservationReport.joins(:observers).pluck(:observer_id, :id)
      }
    }
  end

  csv do
    column :id
    column :is_active
    column :hidden
    column :observation_type
    column I18n.t("shared.status") do |observation|
      observation.validation_status
    end
    column I18n.t("activerecord.models.country.one") do |observation|
      observation.country.name # if observation.country
    end
    column I18n.t("activerecord.models.fmu.one") do |observation|
      observation.fmu&.name # if observation.fmu
    end
    column :location_information
    column I18n.t("observers.observers") do |observation|
      observation.observers.map(&:name).join(", ")
    end
    column I18n.t("activerecord.models.operator") do |observation|
      observation.operator&.name # if observation.operator
    end
    column I18n.t("activerecord.models.government") do |observation|
      observation.governments.map(&:government_entity)
    end
    column :relevant_operators do |observation|
      observation.relevant_operators.map(&:name).join(", ")
    end
    column I18n.t("activerecord.models.category.one") do |observation|
      observation.subcategory&.category&.name
    end
    column I18n.t("activerecord.models.subcategory") do |observation|
      observation.subcategory&.name
    end
    column I18n.t("activerecord.models.law") do |observation|
      observation.law_id
    end
    column Law.human_attribute_name(:written_infraction) do |observation|
      observation.law&.written_infraction
    end
    column Law.human_attribute_name(:infraction) do |observation|
      observation.law&.infraction
    end
    column Law.human_attribute_name(:sanctions) do |observation|
      observation.law&.sanctions
    end
    column Law.human_attribute_name(:min_fine) do |observation|
      observation.law&.min_fine
    end
    column Law.human_attribute_name(:max_fine) do |observation|
      observation.law&.max_fine
    end
    column Law.human_attribute_name(:currency) do |observation|
      observation.law&.currency
    end
    column Law.human_attribute_name(:penal_servitude) do |observation|
      observation.law&.penal_servitude
    end
    column Law.human_attribute_name(:other_penalties) do |observation|
      observation.law&.other_penalties
    end
    column Law.human_attribute_name(:apv) do |observation|
      observation.law&.apv
    end
    column I18n.t("activerecord.models.severity") do |observation|
      observation.severity&.level
    end
    column :publication_date
    column :actions_taken
    column :details
    column :evidence_type
    column I18n.t("active_admin.menu.independent_monitoring.evidence") do |observation|
      evidences = []
      observation.observation_documents.each do |d|
        evidences << d.name
      end
      evidences.join(" | ")
    end
    column :evidence_on_report
    column :concern_opinion
    column :pv
    column :location_accuracy
    column :lat
    column :lng
    column :is_physical_place
    column :litigation_status
    column I18n.t("document_types.Report") do |observation|
      observation.observation_report&.title
    end
    column :monitor_comment
    column I18n.t("activerecord.models.user") do |observation|
      observation.user&.name
    end
    column :modified_user do |observation|
      observation.modified_user&.name
    end
    column :created_at
    column :updated_at
    column :deleted_at
  end

  index do
    selectable_column
    column :id
    column :is_active
    column :hidden
    tag_column I18n.t("shared.status"), :validation_status, sortable: "validation_status"
    column :country, sortable: false
    column :fmu, sortable: false
    column :location_information, sortable: false
    column I18n.t("observers.observers"), class: "col-monitors", sortable: false do |o|
      links = []
      observers = params["scope"].eql?("recycle_bin") ? o.observers.unscope(where: :deleted_at) : o.observers
      observers.each do |observer|
        links << link_to(observer.name, admin_monitor_path(observer.id))
      end
      links.reduce(:+)
    end
    column :observation_type, sortable: "observation_type"
    column :operator, sortable: false
    column I18n.t("governments.governments"), class: "col-governments", sortable: false do |o|
      governments = params["scope"].eql?("recycle_bin") ? o.governments.unscope(where: :deleted_at) : o.governments
      governments.each_with_object([]) do |government, links|
        links << link_to(government.government_entity, admin_government_path(government.id))
      end.reduce(:+)
    end
    column :relevant_operators do |o|
      links = []
      relevant_operators = params["scope"].eql?("recycle_bin") ? o.relevant_operators.unscope(where: :deleted_at) : o.relevant_operators
      relevant_operators.each do |operator|
        links << link_to(operator.name, admin_producer_path(operator.id))
      end
      links.reduce(:+)
    end
    column :subcategory, sortable: false

    column(Law.human_attribute_name(:written_infraction), class: "col-written_infraction", sortable: false) { |o| o.law&.written_infraction }
    column(Law.human_attribute_name(:infraction), class: "col-infration", sortable: false) { |o| o.law&.infraction }
    column(Law.human_attribute_name(:sanctions), class: "col-sanctions", sortable: false) { |o| o.law&.sanctions }
    column(Law.human_attribute_name(:min_fine), class: "col-minimum_fine", sortable: false) { |o| o.law&.min_fine }
    column(Law.human_attribute_name(:max_fine), class: "col-maximum_fine", sortable: false) { |o| o.law&.max_fine }
    column(Law.human_attribute_name(:currency), class: "col-currency") { |o| o.law&.currency }
    column(Law.human_attribute_name(:penal_servitude), class: "col-penal_servitude", sortable: false) { |o| o.law&.penal_servitude }
    column(Law.human_attribute_name(:other_penalties), class: "col-other_penalties", sortable: false) { |o| o.law&.other_penalties }
    column(Law.human_attribute_name(:apv), class: "col-indicator_apv", sortable: false) { |o| o.law&.apv }

    column I18n.t("activerecord.models.severity"), class: "col-severity", sortable: false do |o|
      o&.severity&.level
    end
    column :publication_date, sortable: true
    column :actions_taken, sortable: false do |o|
      o.actions_taken[0..100] + ((o.actions_taken.length >= 100) ? "..." : "") if o.actions_taken
    end
    column :details, class: "col-details"
    column :evidence_type
    column I18n.t("active_admin.menu.independent_monitoring.evidence"), class: "col-evidence" do |o|
      links = []
      documents = params["scope"].eql?("recycle_bin") ? o.observation_documents.unscope(where: :deleted_at) : o.observation_documents
      documents.each do |d|
        links << link_to(d.name, admin_evidence_path(d.id))
      end
      links.reduce(:+)
    end
    column :evidence_on_report, sortable: false
    column :concern_opinion, class: "col-concern_opinion" do |o|
      o.concern_opinion[0..100] + ((o.concern_opinion.length >= 100) ? "..." : "") if o.concern_opinion
    end
    column :pv, sortable: false
    column :location_accuracy, sortable: false
    column :lat, sortable: false
    column :lng, sortable: false
    column :is_physical_place, sortable: false
    column :litigation_status
    column I18n.t("document_types.Report"), class: "col-report", sortable: false do |o|
      title = o.observation_report.title[0..100] + ((o.observation_report.title.length >= 100) ? "..." : "") if o.observation_report&.title
      link_to title, admin_observation_report_path(o.observation_report_id) if o.observation_report.present?
    end
    column :monitor_comment, sortable: false
    column :user, sortable: false
    column :modified_user, sortable: false
    column I18n.t("active_admin.observations_page.modified_user_language"), class: "col-modified_user_language", sortable: false do |o|
      o.modified_user&.locale
    end
    column :created_at
    column :updated_at
    column :deleted_at
    unless params[:scope] == "archived"
      column(I18n.t("active_admin.shared.actions")) do |observation|
        if observation.responsible_for_qc2.include? current_user
          a I18n.t("active_admin.shared.start_qc"), href: start_qc_admin_observation_path(observation), "data-method": :put if observation.validation_status == "Ready for QC2"
          a I18n.t("active_admin.shared.start_qc"), href: new_admin_quality_control_path(quality_control: {reviewable_id: observation.id, reviewable_type: "Observation"}) if observation.validation_status == "QC2 in progress"
        end
      end
    end
    actions

    panel I18n.t("active_admin.producer_documents_dashboard_page.visible_columns") do
      # TODO Translate this
      render partial: "fields",
        locals: {
          page: "observations",
          attributes: [
            ["is_active", Observation.human_attribute_name(:is_active), :checked],
            ["hidden", Observation.human_attribute_name(:hidden), :checked],
            ["status", I18n.t("shared.status"), :checked],
            ["country", Observation.human_attribute_name(:country), :checked],
            ["fmu", Observation.human_attribute_name(:fmu), :checked],
            ["location_information", Observation.human_attribute_name(:location_information), :checked],
            ["monitors", I18n.t("observers.observers"), :checked],
            ["observation_type", Observation.human_attribute_name(:observation_type), :checked],
            ["operator", Observation.human_attribute_name(:operator), :checked],
            ["governments", Observation.human_attribute_name(:governments), :checked],
            ["relevant_operators", Observation.human_attribute_name(:relevant_operators), :checked],
            ["subcategory", Observation.human_attribute_name(:subcategory), :checked],
            ["written_infraction", Law.human_attribute_name(:written_infraction), :checked],
            ["infraction", Law.human_attribute_name(:infraction), :checked],
            ["sanctions", Law.human_attribute_name(:sanctions), :checked],
            ["minimum_fine", Law.human_attribute_name(:min_fine), :checked],
            ["maximum_fine", Law.human_attribute_name(:max_fine), :checked],
            ["currency", Law.human_attribute_name(:currency), :checked],
            ["penal_servitude", Law.human_attribute_name(:penal_servitude), :checked],
            ["other_penalties", Law.human_attribute_name(:other_penalties), :checked],
            ["indicator_apv", Law.human_attribute_name(:apv), :checked],
            ["severity", I18n.t("activerecord.models.severity"), :checked],
            ["publication_date", Observation.human_attribute_name(:publication_date), :checked],
            ["actions_taken", Observation.human_attribute_name(:actions_taken), :checked],
            ["details", Observation.human_attribute_name(:details), :checked],
            ["evidence_type", Observation.human_attribute_name(:evidence_type), :checked],
            ["evidence", I18n.t("active_admin.menu.independent_monitoring.evidence"), :checked],
            ["evidence_on_report", Observation.human_attribute_name(:evidence_on_report), :checked],
            ["concern_opinion", Observation.human_attribute_name(:concern_opinion), :checked],
            ["pv", Observation.human_attribute_name(:pv), :checked],
            ["location_accuracy", Observation.human_attribute_name(:location_accuracy), :checked],
            ["lat", Observation.human_attribute_name(:lat), :checked],
            ["lng", Observation.human_attribute_name(:lng), :checked],
            ["is_physical_place", Observation.human_attribute_name(:is_physical_place), :checked],
            ["litigation_status", Observation.human_attribute_name(:litigation_status), :checked],
            ["report", I18n.t("document_types.Report"), :checked],
            ["monitor_comment", Observation.human_attribute_name(:monitor_comment), :checked],
            ["user", Observation.human_attribute_name(:user), :checked],
            ["modified_user", Observation.human_attribute_name(:modified_user), :checked],
            ["modified_user_language", I18n.t("active_admin.observations_page.modified_user_language"), :checked],
            ["created_at", Observation.human_attribute_name(:created_at), :checked],
            ["updated_at", Observation.human_attribute_name(:updated_at), :checked],
            ["deleted_at", Observation.human_attribute_name(:deleted_at), :checked]
          ]
        }
    end
  end

  form do |f|
    allow_override = current_user.user_permission.user_role == "admin"
    visibility = {input_html: {disabled: !allow_override}}

    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("observations.info") do
      f.input :id, input_html: {disabled: true}
    end
    f.inputs I18n.t("shared.status") do
      f.input :is_active, input_html: {disabled: true}
      f.input :hidden, **visibility
      f.input :validation_status, input_html: {disabled: true}
    end
    f.inputs I18n.t("active_admin.observations_page.details") do
      f.input :observation_type, input_html: {disabled: true}
      if allow_override
        if f.object.observation_type == "operator"
          f.input :non_concession_activity if f.object.country.nil? || f.object.non_concession_activity_enabled?
          f.input :fmu_id,
            as: :nested_select,
            level_1: {
              attribute: :country_id,
              collection: Country.with_translations(I18n.locale)
            },
            level_2: {
              attribute: :operator_id,
              order: "operators.name_asc",
              minimum_input_length: 0,
              url: "/admin/producers"
            },
            level_3: {
              attribute: :fmu_id,
              minimum_input_length: 0,
              order: "fmus.name_asc"
            }
        else
          f.input :country
        end

        f.input :severity_id,
          as: :nested_select,
          display_name: :details,
          level_1: {
            attribute: :category_id,
            display_name: :name,
            minimum_input_length: 0,
            order: "category_translations.name_asc"
          },
          level_2: {
            attribute: :subcategory_id,
            display_name: :name,
            minimum_input_length: 0,
            order: "subcategory_translations.name_asc"
          },
          level_3: {
            attribute: :severity_id,
            minimum_input_length: 0,
            fields: [:details],
            order: "severity_translations.details_asc"
          }
        f.input :law, collection:
          Law.with_country_subcategory.map {
            ["#{it.country.name} - #{it.subcategory.name} - #{it.written_infraction}", it.id]
          }
      else
        f.input :country, input_html: {disabled: true}
        f.input :operator, input_html: {disabled: true} if f.object.observation_type == "operator"
        f.input :non_concession_activity, input_html: {disabled: true} if f.object.observation_type == "operator" && (f.object.country.nil? || f.object.non_concession_activity_enabled?)
        f.input :fmu, input_html: {disabled: true} if f.object.observation_type == "operator"
        f.input :subcategory, input_html: {disabled: true}
        f.input :severity, as: :string, input_html: {
          disabled: true, value: "#{f.object.severity&.level} - #{f.object.severity&.details&.first(80)}"
        }
        f.input :law, as: :string, input_html: {disabled: true, value: f.object.law&.written_infraction}
      end

      f.input :is_physical_place, **visibility
      f.input :location_information, **visibility if f.object.observation_type == "operator"
      f.input :observers, input_html: {disabled: true}

      f.input :relevant_operator_ids,
        label: Observation.human_attribute_name(:relevant_operators),
        as: :select, collection: Operator.all.map { |o| [o.name, o.id] },
        input_html: {multiple: true, disabled: !allow_override}
      if f.object.observation_type == "government"
        f.input :government_ids,
          label: I18n.t("governments.governments"),
          as: :select,
          collection: Government.all.map { |g| [g.government_entity, g.id] },
          input_html: {disabled: !allow_override, multiple: true}
      end
      f.input :publication_date,
        as: :date_time_picker,
        picker_options: {timepicker: false, format: "Y-m-d"},
        input_html: {disabled: true}
      f.input :pv, **visibility
      f.input :location_accuracy, as: :select, **visibility
      f.input :lat, **visibility
      f.input :lng, **visibility
      f.input :actions_taken, **visibility
      f.input :observation_report, as: :select, **visibility
      f.input :evidence_type, as: :select, **visibility
      f.input :evidence_on_report, **visibility
      f.input :observation_documents,
        as: :select,
        collection: (f.object.observation_documents + (f.object.observation_report&.observation_documents || [])).uniq,
        **visibility
    end

    f.inputs I18n.t("active_admin.shared.translated_fields") do
      f.input :locale, input_html: {disabled: true}
      if f.object.published?
        f.input :force_translations_from, label: I18n.t("active_admin.shared.translate_from"),
          as: :select,
          collection: I18n.available_locales.sort,
          include_blank: true,
          hint: I18n.t("active_admin.shared.translate_from_hint"),
          input_html: {class: "translate_from"}
      end
      f.translated_inputs "Translations", switch_locale: false do |t|
        t.input :details, **visibility
        t.input :details_translated_from, input_html: {disabled: true}
        t.input :concern_opinion, **visibility
        t.input :concern_opinion_translated_from, input_html: {disabled: true}
        t.input :litigation_status, **visibility
        t.input :litigation_status_translated_from, input_html: {disabled: true}
      end
    end
    f.actions
  end

  show do
    render partial: "attributes_table", locals: {observation: resource}
  end
end
