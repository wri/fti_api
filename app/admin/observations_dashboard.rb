# frozen_string_literal: true

ActiveAdmin.register ObservationStatistic, as: "Observations Dashboard" do
  extend BackRedirectable

  menu false

  actions :index

  filter :country_id,
    as: :select,
    label: proc { I18n.t("activerecord.models.country.one") },
    collection: -> {
      [[I18n.t("active_admin.producer_documents_dashboard_page.all_countries"), "null"]] +
        Country.active.order(:name).map { |c| [c.name, c.id] }
    }
  filter :observation_type, as: :select, collection: ObservationStatistic.observation_types.sort
  filter :operator, as: :select, collection: -> { Operator.where(id: Observation.pluck(:operator_id)).order(:name) }
  filter :fmu_forest_type, as: :select, collection: -> { ForestType.select_collection }
  filter :category, as: :select, collection: -> { Category.by_name_asc }
  filter :subcategory, as: :select, collection: -> { Subcategory.by_name_asc }
  filter :severity_level, as: :select, collection: [
    [I18n.t("filters.unknown"), 0],
    [I18n.t("filters.low"), 1],
    [I18n.t("filters.medium"), 2],
    [I18n.t("filters.high"), 3]
  ]
  filter :hidden
  filter :is_active
  filter :date

  dependent_filters do
    {
      country_id: {
        fmu_forest_type: Fmu.distinct.pluck(:country_id, :forest_type).map { |c, f| [c, ForestType::TYPES[f][:index]] },
        operator_id: Operator.pluck(:country_id, :id)
      },
      category_id: {
        subcategory_id: Subcategory.pluck(:category_id, :id)
      }
    }
  end

  index title: I18n.t("active_admin.observations_dashboard_page.name") do
    column :date, sortable: false do |resource|
      resource.date.to_date
    end
    column :country, sortable: false do |resource|
      if resource.country.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.all_countries")
      else
        link_to resource.country.name, admin_country_path(resource.country)
      end
    end
    column :observation_type, sortable: false do |r|
      r.observation_type.presence || I18n.t("active_admin.observations_dashboard_page.all_types")
    end
    column :operator, sortable: false do |r|
      if r.operator.nil?
        I18n.t("active_admin.observations_dashboard_page.all_operators")
      else
        link_to r.operator.name, admin_producer_path(r.operator)
      end
    end
    column :fmu_forest_type, sortable: false do |r|
      if r.fmu_forest_type.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.all_forest_types")
      else
        ForestType::TYPES[r.fmu_forest_type][:label]
      end
    end
    column :severity_level, sortable: false do |r|
      r.severity_level.presence || I18n.t("active_admin.observations_dashboard_page.all_levels")
    end
    column :category do |r|
      if r.category.nil?
        I18n.t("active_admin.observations_dashboard_page.all_categories")
      else
        link_to r.category.name, admin_category_path(r.category)
      end
    end
    column :subcategory do |r|
      if r.subcategory.nil?
        I18n.t("active_admin.observations_dashboard_page.all_subcategories")
      else
        link_to r.subcategory.name, admin_subcategory_path(r.subcategory)
      end
    end
    column :is_active do |r|
      r.is_active.nil? ? I18n.t("active_admin.observations_dashboard_page.any") : r.is_active
    end
    column :hidden do |r|
      r.hidden.nil? ? I18n.t("active_admin.observations_dashboard_page.any") : r.hidden
    end
    column :created
    column :ready_for_qc
    column :qc_in_progress
    column :approved
    column :rejected
    column :needs_revision
    column :ready_for_publication
    column :published_no_comments
    column :published_not_modified
    column :published_modified
    column :published_all
    column :total_count, sortable: false
    show_on_chart = if params.dig(:q, :country_id_eq).present?
      collection
    else
      collection.select { |r| r.country_id.nil? }
    end
    grouped_sod = show_on_chart.group_by(&:date)
    hidden = {dataset: {hidden: true}}
    get_data = ->(&block) { grouped_sod.map { |date, data| {date.to_date => data.map(&block).max} }.reduce(&:merge) }
    render partial: "score_evolution", locals: {
      scores: [
        {name: "Created", **hidden, data: get_data.call(&:created)},
        {name: "Ready for QC", **hidden, data: get_data.call(&:ready_for_qc)},
        {name: "QC in Progress", **hidden, data: get_data.call(&:qc_in_progress)},
        {name: "Approved", **hidden, data: get_data.call(&:approved)},
        {name: "Rejected", **hidden, data: get_data.call(&:rejected)},
        {name: "Needs Revision", **hidden, data: get_data.call(&:needs_revision)},
        {name: "Ready for publication", **hidden, data: get_data.call(&:ready_for_publication)},
        {name: "Published no comments", **hidden, data: get_data.call(&:published_no_comments)},
        {name: "Published not modified", **hidden, data: get_data.call(&:published_not_modified)},
        {name: "Published modified", **hidden, data: get_data.call(&:published_modified)},
        {name: "Published all", **hidden, data: get_data.call(&:published_all)}
      ]
    }

    panel "Visible columns" do
      render partial: "fields", locals: {
        attributes: [
          ["date", I18n.t("activerecord.attributes.operator_document_statistic.date")],
          ["country", I18n.t("activerecord.attributes.operator_document_statistic.country.one")],
          ["is_active", I18n.t("activerecord.attributes.observation.is_active")],
          ["hidden", I18n.t("activerecord.attributes.observation.hidden")],
          ["observation_type", I18n.t("activerecord.attributes.observation.observation_type")],
          ["operator", I18n.t("activerecord.models.operator")],
          ["severity_level", I18n.t("activerecord.attributes.severity.level")],
          ["category", I18n.t("activerecord.models.category.one")],
          ["subcategory", I18n.t("activerecord.models.subcategory")],
          ["fmu_forest_type", I18n.t("activerecord.attributes.observation_history.fmu_forest_type")],
          ["created", I18n.t("shared.created")],
          ["ready_for_qc", I18n.t("activerecord.enums.observation.statuses.Ready for QC")],
          ["qc_in_progress", I18n.t("activerecord.enums.observation.statuses.QC in progress")],
          ["approved", I18n.t("activerecord.enums.observation.statuses.Approved")],
          ["rejected", I18n.t("activerecord.enums.observation.statuses.Rejected")],
          ["needs_revision", I18n.t("activerecord.enums.observation.statuses.Needs revision")],
          ["ready_for_publication", I18n.t("activerecord.enums.observation.statuses.Ready for publication")],
          ["published_no_comments", I18n.t("activerecord.enums.observation.statuses.Published (no comments)")],
          ["published_modified", I18n.t("activerecord.enums.observation.statuses.Published (modified)")],
          ["published_not_modified", I18n.t("activerecord.enums.observation.statuses.Published (not modified)")],
          ["published_all", I18n.t("active_admin.observations_dashboard_page.published_all")],
          ["total_count", I18n.t("active_admin.observation_reports_dashboard_page.total_count")]
        ],
        unchecked: [
          ["operator", I18n.t("activerecord.models.operator")],
          ["severity_level", I18n.t("activerecord.attributes.observation_history.severity_level")],
          ["observation_type", I18n.t("activerecord.attributes.observation.observation_type")],
          ["category", I18n.t("activerecord.models.category.one")],
          ["subcategory", I18n.t("activerecord.models.subcategory")],
          ["fmu_forest_type", I18n.t("activerecord.attributes.observation_history.fmu_forest_type")],
          ["ready_for_qc", I18n.t("activerecord.enums.observation.statuses.Ready for QC")],
          ["approved", I18n.t("activerecord.enums.observation.statuses.Approved")],
          ["rejected", I18n.t("activerecord.enums.observation.statuses.Rejected")],
          ["needs_revision", I18n.t("activerecord.enums.observation.statuses.Needs revision")],
          ["ready_for_publication", I18n.t("activerecord.enums.observation.statuses.Ready for publication")],
          ["published_no_comments", I18n.t("activerecord.enums.observation.statuses.Published (no comments)")],
          ["published_modified", I18n.t("activerecord.enums.observation.statuses.Published (modified)")],
          ["published_not_modified", I18n.t("activerecord.enums.observation.statuses.Published (not modified)")],
          ["total_count", I18n.t("active_admin.observation_reports_dashboard_page.total_count")],
          ["created", I18n.t("shared.created")],
          ["qc_in_progress", I18n.t("activerecord.enums.observation.statuses.QC in progress")]
        ]
      }
    end
  end

  csv do
    column :date do |resource|
      resource.date.strftime("%d/%m/%Y")
    end
    column :country, &:country_name
    column :operator do |r|
      if r.operator.nil?
        I18n.t("active_admin.observations_dashboard_page.all_operators")
      else
        r.operator.name
      end
    end
    column :observation_type do |r|
      if r.observation_type.nil?
        I18n.t("active_admin.observations_dashboard_page.all_types")
      else
        r.observation_type
      end
    end
    column :fmu_forest_type do |r|
      if r.fmu_forest_type.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.all_forest_types")
      else
        ForestType::TYPES[r.fmu_forest_type][:label]
      end
    end
    column :validation_status do |r|
      if r.validation_status.nil?
        I18n.t("active_admin.observations_dashboard_page.all_statuses")
      else
        r.validation_status
      end
    end
    column :category do |r|
      if r.category.nil?
        I18n.t("active_admin.observations_dashboard_page.all_categories")
      else
        r.category.name
      end
    end
    column :subcategory do |r|
      if r.subcategory.nil?
        I18n.t("active_admin.observations_dashboard_page.all_subcategories")
      else
        r.subcategory.name
      end
    end
    column :severity_level
    column :created
    column :ready_for_qc
    column :qc_in_progress
    column :approved
    column :rejected
    column :needs_revision
    column :ready_for_publication
    column :published_no_comments
    column :published_not_modified
    column :published_modified
    column :published_all
    column :total_count
  end

  controller do
    skip_before_action :restore_search_filters
    skip_after_action :save_search_filters
    before_action :set_default_filters
    before_action :set_paging

    def set_default_filters
      params[:q] ||= {}
      params[:q][:date_gteq] = 1.year.ago if params.dig(:q, :date_gteq).blank?
    end

    # config.per_page didn't work, but this does probably related to use of paginate_array? dunno
    def set_paging
      @page = params[:page]
      @per_page = 500
    end

    def find_collection(options = {})
      collection = ObservationStatistic.query_dashboard_report(params[:q] || {})
      # keep the ransack to maintain filters in active admin
      @search = ObservationStatistic.ransack(params[:q] || {})
      # collection must be paged otherwise aa is complaining
      Kaminari.paginate_array(collection).page(@page).per(@per_page)
    end
  end
end
