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
  filter :operator, as: :select, collection: -> { Operator.where(id: Observation.select(:operator_id)).order(:name) }
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

  index title: proc { I18n.t("active_admin.observations_dashboard_page.name") } do
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
    chart_collection = if params.dig(:q, :country_id_eq).present?
      collection
    else
      collection.select { |r| r.country_id.nil? }
    end
    chart_collection_by_date = chart_collection.group_by(&:date)
    hidden = {dataset: {hidden: true}}
    get_data = ->(&block) { chart_collection_by_date.map { |date, data| {date.to_date => data.map(&block).max} }.reduce(&:merge) }
    get_score = ->(score_key, options = {}) {
      {
        name: ObservationStatistic.human_attribute_name(score_key),
        data: get_data.call(&score_key),
        **{dataset: {id: score_key.to_s}}.deep_merge(options)
      }
    }

    render partial: "score_evolution", locals: {
      scores: [
        get_score.call(:created, hidden),
        get_score.call(:ready_for_qc, hidden),
        get_score.call(:qc_in_progress, hidden),
        get_score.call(:approved, hidden),
        get_score.call(:rejected, hidden),
        get_score.call(:needs_revision, hidden),
        get_score.call(:ready_for_publication, hidden),
        get_score.call(:published_no_comments, hidden),
        get_score.call(:published_not_modified, hidden),
        get_score.call(:published_modified, hidden),
        get_score.call(:published_all, hidden)
      ]
    }

    panel "Visible columns" do
      render partial: "fields", locals: {
        page: "observations_dashboard",
        attributes: [
          ["date", I18n.t("activerecord.attributes.operator_document_statistic.date"), :checked],
          ["country", I18n.t("activerecord.attributes.operator_document_statistic.country.one"), :checked],
          ["observation_type", I18n.t("activerecord.attributes.observation.observation_type")],
          ["operator", I18n.t("activerecord.models.operator")],
          ["fmu_forest_type", I18n.t("activerecord.attributes.observation_history.fmu_forest_type")],
          ["severity_level", I18n.t("activerecord.attributes.severity.level")],
          ["category", I18n.t("activerecord.models.category.one")],
          ["subcategory", I18n.t("activerecord.models.subcategory")],
          ["is_active", I18n.t("activerecord.attributes.observation.is_active"), :checked],
          ["hidden", I18n.t("activerecord.attributes.observation.hidden"), :checked],
          ["created", ObservationStatistic.human_attribute_name(:created)],
          ["ready_for_qc", ObservationStatistic.human_attribute_name(:ready_for_qc)],
          ["qc_in_progress", ObservationStatistic.human_attribute_name(:qc_in_progress)],
          ["approved", ObservationStatistic.human_attribute_name(:approved)],
          ["rejected", ObservationStatistic.human_attribute_name(:rejected)],
          ["needs_revision", ObservationStatistic.human_attribute_name(:needs_revision)],
          ["ready_for_publication", ObservationStatistic.human_attribute_name(:ready_for_publication)],
          ["published_no_comments", ObservationStatistic.human_attribute_name(:published_no_comments)],
          ["published_modified", ObservationStatistic.human_attribute_name(:published_modified)],
          ["published_not_modified", ObservationStatistic.human_attribute_name(:published_not_modified)],
          ["published_all", ObservationStatistic.human_attribute_name(:published_all), :checked],
          ["total_count", ObservationStatistic.human_attribute_name(:total_count)]
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
