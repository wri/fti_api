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

  before_action do
    if %w[POST PATCH PUT].include?(request.method) && action_name != "batch_action"
      resource.user_type = :admin
    end
  end

  scope_to do
    Class.new do
      def self.observations
        Observation.unscoped
      end
    end
  end

  actions :all, except: [:new]
  controller do
    def permitted_params
      if current_user.user_permission.user_role == "bo_manager"
        params.permit(observation: [:validation_status, :admin_comment])
      else
        params.permit(
          observation: [
            :name, :lng, :pv, :lat, :lon, :subcategory_id, :severity_id, :country_id, :operator_id, :user_type,
            :validation_status, :publication_date, :observation_report_id, :location_information, :evidence_type,
            :evidence_on_report, :location_accuracy, :law_id, :fmu_id, :hidden, :admin_comment,
            :monitor_comment, :actions_taken, :is_physical_place,
            relevant_operator_ids: [], government_ids: [],
            observation_document_ids: [],
            translations_attributes: [:id, :locale, :details, :concern_opinion, :litigation_status, :_destroy]
          ]
        )
      end
    end
  end

  member_action :perform_qc, method: [:put, :get] do
    @page_title = I18n.t("active_admin.observations_page.perform_qc")
    if request.get?
      if resource.validation_status == "QC in progress"
        render "perform_qc"
      else
        redirect_to collection_path, alert: I18n.t("active_admin.observations_page.not_in_qc_in_progress")
      end
    elsif resource.update permitted_params[:observation]
      redirect_to collection_path, notice: I18n.t("active_admin.observations_page.performed_qc")
    else
      render "perform_qc"
    end
  end

  member_action :ready_for_publication, method: :put do
    resource.validation_status = Observation.validation_statuses["Ready for publication"]
    notice = resource.save ? I18n.t("active_admin.observations_page.moved_ready") : I18n.t("active_admin.observations_page.not_modified")
    redirect_to collection_path, notice: notice
  end

  member_action :start_qc, method: [:put, :get] do
    resource.user_type = :admin
    resource.validation_status = Observation.validation_statuses["QC in progress"]
    if resource.save
      redirect_to perform_qc_admin_observation_path(resource), notice: I18n.t("active_admin.observations_page.moved_qc_in_progress")
    else
      redirect_to collection_path, notice: I18n.t("active_admin.observations_page.not_modified")
    end
  end

  action_item :ready_for_publication, only: :show do
    if resource.validation_status == "QC in progress"
      link_to I18n.t("active_admin.observations_page.ready_for_publication"), ready_for_publication_admin_observation_path(observation),
        method: :put, data: {confirm: I18n.t("active_admin.observations_page.confirm_ready_publication")},
        notice: I18n.t("active_admin.observations_page.approved")
    end
  end

  action_item :needs_revision, only: :show do
    if resource.validation_status == "QC in progress"
      link_to I18n.t("active_admin.observations_page.needs_revision"), perform_qc_admin_observation_path(observation)
    end
  end

  action_item :start_qc, only: :show do
    if resource.validation_status == "Ready for QC"
      link_to I18n.t("active_admin.observations_page.start_qc"), start_qc_admin_observation_path(observation),
        method: :put, notice: I18n.t("active_admin.observations_page.in_qc")
    end
  end

  # Bulk actions should be available only if this env flag is set to `true`
  if ENV.fetch("BULK_EDIT_OBSERVATIONS", "TRUE").upcase == "TRUE"
    batch_action :move_to_qc_in_progress, confirm: I18n.t("active_admin.observations_page.bulk_confirm_qc") do |ids|
      batch_action_collection.find(ids).each do |observation|
        next unless observation.validation_status == "Ready for QC"

        observation.update(validation_status: "QC in progress")
      end
      redirect_to collection_path, notice: I18n.t("active_admin.observations_page.qc_started")
    end

    batch_action :move_to_ready_for_publication, confirm: I18n.t("active_admin.observations_page.bulk_ready_for_publication") do |ids|
      batch_action_collection.find(ids).each do |observation|
        next unless observation.validation_status == "QC in progress"

        observation.update(validation_status: "Ready for publication")
      end
      redirect_to collection_path, notice: I18n.t("active_admin.observations_page.ready_to_publish")
    end

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

  sidebar I18n.t("active_admin.operator_page.documents"), only: [:show, :perform_qc] do
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

  filter :id, as: :numeric_range
  filter :validation_status,
    as: :select,
    input_html: {multiple: true},
    collection: -> { Observation.validation_statuses.sort }
  filter :country, as: :select, collection: -> { Country.with_observations.by_name_asc }
  filter :operator, as: :select, collection: -> { Operator.by_name_asc }
  filter :fmu, as: :select, collection: -> { Fmu.by_name_asc }
  filter :governments, as: :select, label: -> { I18n.t("activerecord.attributes.government.government_entity") }, collection: -> { Government.by_entity_asc }
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
    column I18n.t("activerecord.attributes.observation.relevant_operators") do |observation|
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
    column I18n.t("activerecord.attributes.law.written_infraction") do |observation|
      observation.law&.written_infraction
    end
    column I18n.t("activerecord.attributes.law.infraction") do |observation|
      observation.law&.infraction
    end
    column I18n.t("activerecord.attributes.law.sanctions") do |observation|
      observation.law&.sanctions
    end
    column I18n.t("activerecord.attributes.law.min_fine") do |observation|
      observation.law&.min_fine
    end
    column I18n.t("activerecord.attributes.law.max_fine") do |observation|
      observation.law&.max_fine
    end
    column I18n.t("activerecord.attributes.law.currency") do |observation|
      observation.law&.currency
    end
    column I18n.t("activerecord.attributes.law.penal_servitude") do |observation|
      observation.law&.penal_servitude
    end
    column I18n.t("activerecord.attributes.law.other_penalties") do |observation|
      observation.law&.other_penalties
    end
    column I18n.t("active_admin.laws_page.indicator_apv") do |observation|
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
    column :admin_comment
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
      observers.with_translations(I18n.locale).each do |observer|
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

    column(I18n.t("active_admin.laws_page.written_infraction"), class: "col-written_infraction", sortable: false) { |o| o.law&.written_infraction }
    column(I18n.t("active_admin.laws_page.infraction"), class: "col-infration", sortable: false) { |o| o.law&.infraction }
    column(I18n.t("active_admin.laws_page.sanctions"), class: "col-sanctions", sortable: false) { |o| o.law&.sanctions }
    column(I18n.t("active_admin.laws_page.min_fine"), class: "col-minimum_fine", sortable: false) { |o| o.law&.min_fine }
    column(I18n.t("active_admin.laws_page.max_fine"), class: "col-maximum_fine", sortable: false) { |o| o.law&.max_fine }
    column(I18n.t("activerecord.attributes.law.currency"), class: "col-currency") { |o| o.law&.currency }
    column(I18n.t("activerecord.attributes.law.penal_servitude"), class: "col-penal_servitude", sortable: false) { |o| o.law&.penal_servitude }
    column(I18n.t("activerecord.attributes.law.other_penalties"), class: "col-other_penalties", sortable: false) { |o| o.law&.other_penalties }
    column(I18n.t("active_admin.laws_page.indicator_apv"), class: "col-indicator_apv", sortable: false) { |o| o.law&.apv }

    column I18n.t("activerecord.models.severity"), class: "col-severity", sortable: false do |o|
      o&.severity&.level
    end
    column :publication_date, sortable: true
    column :actions_taken, sortable: false do |o|
      o.actions_taken[0..100] + ((o.actions_taken.length >= 100) ? "..." : "") if o.actions_taken
    end
    column I18n.t("activerecord.attributes.observation/translation.details"), class: "col-details", &:details
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
    column I18n.t("activerecord.attributes.observation/translation.concern_opinion"), class: "col-concern_opinion" do |o|
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
    column :admin_comment, sortable: false
    column :monitor_comment, sortable: false
    column :user, sortable: false
    column :modified_user, sortable: false
    column I18n.t("active_admin.observations_page.modified_user_language"), class: "col-modified_user_language", sortable: false do |o|
      o.modified_user&.locale
    end
    column :created_at
    column :updated_at
    column :deleted_at
    column(I18n.t("active_admin.shared.actions")) do |observation|
      a I18n.t("active_admin.observations_page.start_qc"), href: start_qc_admin_observation_path(observation), "data-method": :put if observation.validation_status == "Ready for QC"
      a I18n.t("active_admin.observations_page.needs_revision"), href: perform_qc_admin_observation_path(observation) if observation.validation_status == "QC in progress"
      a I18n.t("active_admin.observations_page.ready_to_publish"), href: ready_for_publication_admin_observation_path(observation), "data-method": :put if observation.validation_status == "QC in progress"
    end
    actions

    panel I18n.t("active_admin.producer_documents_dashboard_page.visible_columns") do
      # TODO Translate this
      render partial: "fields",
        locals: {
          page: "observations",
          attributes: [
            ["is_active", I18n.t("activerecord.attributes.observation.is_active"), :checked],
            ["hidden", I18n.t("activerecord.attributes.observation.hidden"), :checked],
            ["status", I18n.t("shared.status"), :checked],
            ["country", I18n.t("activerecord.attributes.observation.country.one"), :checked],
            ["fmu", I18n.t("activerecord.attributes.observation.fmu.one"), :checked],
            ["location_information", I18n.t("activerecord.attributes.observation.location_information"), :checked],
            ["monitors", I18n.t("observers.observers"), :checked],
            ["observation_type", I18n.t("activerecord.attributes.observation.observation_type"), :checked],
            ["operator", I18n.t("activerecord.attributes.observation.operator"), :checked],
            ["governments", I18n.t("activerecord.attributes.observation.governments"), :checked],
            ["relevant_operators", I18n.t("activerecord.attributes.observation.relevant_operators"), :checked],
            ["subcategory", I18n.t("activerecord.attributes.observation.subcategory"), :checked],
            ["written_infraction", I18n.t("active_admin.laws_page.written_infraction"), :checked],
            ["infraction", I18n.t("active_admin.laws_page.infraction"), :checked],
            ["sanctions", I18n.t("active_admin.laws_page.sanctions"), :checked],
            ["minimum_fine", I18n.t("active_admin.laws_page.min_fine"), :checked],
            ["maximum_fine", I18n.t("active_admin.laws_page.max_fine"), :checked],
            ["currency", I18n.t("activerecord.attributes.law.currency"), :checked],
            ["penal_servitude", I18n.t("activerecord.attributes.law.penal_servitude"), :checked],
            ["other_penalties", I18n.t("activerecord.attributes.law.other_penalties"), :checked],
            ["indicator_apv", I18n.t("active_admin.laws_page.indicator_apv"), :checked],
            ["severity", I18n.t("activerecord.models.severity"), :checked],
            ["publication_date", I18n.t("activerecord.attributes.observation.publication_date"), :checked],
            ["actions_taken", I18n.t("activerecord.attributes.observation.actions_taken"), :checked],
            ["details", I18n.t("activerecord.attributes.observation/translation.details"), :checked],
            ["evidence_type", I18n.t("activerecord.attributes.observation.evidence_type"), :checked],
            ["evidence", I18n.t("active_admin.menu.independent_monitoring.evidence"), :checked],
            ["evidence_on_report", I18n.t("activerecord.attributes.observation.evidence_on_report"), :checked],
            ["concern_opinion", I18n.t("activerecord.attributes.observation/translation.concern_opinion"), :checked],
            ["pv", I18n.t("activerecord.attributes.observation.pv"), :checked],
            ["location_accuracy", I18n.t("activerecord.attributes.observation.location_accuracy"), :checked],
            ["lat", I18n.t("activerecord.attributes.observation.lat"), :checked],
            ["lng", I18n.t("activerecord.attributes.observation.lng"), :checked],
            ["is_physical_place", I18n.t("activerecord.attributes.observation.is_physical_place"), :checked],
            ["litigation_status", I18n.t("activerecord.attributes.observation/translation.litigation_status"), :checked],
            ["report", I18n.t("document_types.Report"), :checked],
            ["admin_comment", I18n.t("activerecord.attributes.observation.admin_comment"), :checked],
            ["monitor_comment", I18n.t("activerecord.attributes.observation.monitor_comment"), :checked],
            ["user", I18n.t("activerecord.attributes.observation.user"), :checked],
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
      if Observation::STATUS_TRANSITIONS[:admin].key?(f.object.validation_status)
        valid_statuses = [Observation::STATUS_TRANSITIONS[:admin][f.object.validation_status], f.object.validation_status].flatten
        f.input :validation_status, collection: valid_statuses
      else
        f.input :validation_status, {input_html: {disabled: true}}
      end
    end
    f.inputs I18n.t("active_admin.observations_page.details") do
      f.input :observation_type, input_html: {disabled: true}
      if allow_override
        if f.object.observation_type == "operator"
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
              order: "fmu_translations.name_asc"
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
            ["#{_1.country.name} - #{_1.subcategory.name} - #{_1.written_infraction}", _1.id]
          }
      else
        f.input :country, input_html: {disabled: true}
        f.input :operator, input_html: {disabled: true} if f.object.observation_type == "operator"
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
        label: I18n.t("activerecord.attributes.observation.relevant_operators"),
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
      f.input :admin_comment
      f.input :monitor_comment, **visibility
      f.input :observation_report, as: :select, **visibility
      f.input :evidence_type, as: :select, **visibility
      f.input :evidence_on_report, **visibility
      f.input :observation_documents,
        as: :select,
        collection: (f.object.observation_documents + (f.object.observation_report&.observation_documents || [])).uniq,
        **visibility
    end

    f.inputs I18n.t("active_admin.shared.translated_fields") do
      f.translated_inputs "Translations", switch_locale: false do |t|
        t.input :details, **visibility
        t.input :concern_opinion, **visibility
        t.input :litigation_status, **visibility
      end
    end
    f.actions
  end

  show do
    render partial: "attributes_table", locals: {observation: resource}

    active_admin_comments
  end
end
