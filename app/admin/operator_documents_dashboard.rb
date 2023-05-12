# frozen_string_literal: true

ActiveAdmin.register OperatorDocumentStatistic, as: "Producer Documents Dashboard" do
  extend BackRedirectable

  config.sort_order = "date_desc"
  config.paginate = false
  config.per_page = 10000

  menu false

  actions :index

  filter :by_country, label: proc { I18n.t("activerecord.models.country.one") }, as: :select,
    collection: -> {
                  [[I18n.t("active_admin.producer_documents_dashboard_page.all_countries"), "null"]] +
                    Country.active.order(:name).map { |c| [c.name, c.id] }
                }
  filter :required_operator_document_group, as: :select,
    collection: -> { RequiredOperatorDocumentGroup.without_publication_authorization.order(:name) }
  filter :document_type_eq, label: proc { I18n.t("activerecord.enums.operator_document.types.name") }, as: :select,
    collection: [
      [I18n.t("activerecord.enums.operator_document.types.fmu"), :fmu],
      [I18n.t("activerecord.enums.operator_document.types.country"), :country]
    ]
  filter :fmu_forest_type_eq, label: proc { I18n.t("activerecord.attributes.fmu.forest_type") }, as: :select, collection: -> { ForestType.select_collection }
  filter :date

  index title: proc { I18n.t("active_admin.producer_documents_dashboard_page.name") }, pagination_total: false do
    column :date do |resource|
      resource.date.to_date
    end
    column :country do |resource|
      if resource.country.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.all_countries")
      else
        link_to resource.country.name, admin_country_path(resource.country)
      end
    end
    column :required_operator_document_group do |r|
      if r.required_operator_document_group.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.all_groups")
      else
        link_to r.required_operator_document_group.name, admin_required_operator_document_group_path(r.required_operator_document_group)
      end
    end
    column :fmu_forest_type do |r|
      if r.fmu_forest_type.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.all_forest_types")
      else
        ForestType::TYPES[r.fmu_forest_type][:label]
      end
    end
    column :document_type do |r|
      if r.document_type.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.fmu_country")
      else
        r.document_type.humanize
      end
    end
    column :valid_and_expired_count, sortable: false
    column :valid_count, sortable: false
    column :expired_count, sortable: false
    column :pending_count, sortable: false
    column :invalid_count, sortable: false
    column :not_required_count, sortable: false
    column :not_provided_count, sortable: false

    chart_collection = if params.dig(:q, :by_country).present?
      collection
    else
      collection.select { |r| r.country_id.nil? }
    end
    chart_collection_by_date = chart_collection.group_by(&:date)
    hidden = {dataset: {hidden: true}}
    get_data = ->(&block) { chart_collection_by_date.map { |date, data| {date.to_date => data.map(&block).max} }.reduce(&:merge) }
    get_score = ->(score_key, options = {}) {
      {
        name: OperatorDocumentStatistic.human_attribute_name(score_key),
        data: get_data.call(&score_key),
        **{dataset: {id: score_key.to_s}}.deep_merge(options)
      }
    }
    render partial: "score_evolution", locals: {
      scores: [
        get_score.call(:not_provided_count, hidden),
        get_score.call(:pending_count, hidden),
        get_score.call(:invalid_count, hidden),
        get_score.call(:valid_and_expired_count),
        get_score.call(:valid_count),
        get_score.call(:expired_count),
        get_score.call(:not_required_count, hidden)
      ]
    }

    panel I18n.t("active_admin.producer_documents_dashboard_page.visible_columns") do
      render partial: "fields", locals: {
        page: "producer_documents_dashboard",
        attributes: [
          ["date", I18n.t("activerecord.attributes.operator_document_statistic.date"), :checked],
          ["country", I18n.t("activerecord.attributes.operator_document_statistic.country.one"), :checked],
          ["required_operator_document_group", I18n.t("activerecord.models.required_operator_document_group.one")],
          ["fmu_forest_type", I18n.t("activerecord.attributes.fmu.forest_type")],
          ["document_type", I18n.t("activerecord.attributes.required_gov_document.document_type")],
          ["valid_and_expired_count", OperatorDocumentStatistic.human_attribute_name(:valid_and_expired_count), :checked],
          ["valid_count", OperatorDocumentStatistic.human_attribute_name(:valid_count), :checked],
          ["expired_count", OperatorDocumentStatistic.human_attribute_name(:expired_count), :checked],
          ["invalid_count", OperatorDocumentStatistic.human_attribute_name(:invalid_count)],
          ["pending_count", OperatorDocumentStatistic.human_attribute_name(:pending_count)],
          ["not_provided_count", OperatorDocumentStatistic.human_attribute_name(:not_provided_count)],
          ["not_required_count", OperatorDocumentStatistic.human_attribute_name(:not_required_count)]
        ]
      }
    end
  end

  csv do
    column :date do |resource|
      resource.date.strftime("%d/%m/%Y")
    end
    column :country, &:country_name
    column :required_operator_document_group do |r|
      if r.required_operator_document_group.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.all_groups")
      else
        r.required_operator_document_group.name
      end
    end
    column :fmu_forest_type do |r|
      if r.fmu_forest_type.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.all_forest_types")
      else
        ForestType::TYPES[r.fmu_forest_type][:label]
      end
    end
    column :document_type do |r|
      if r.document_type.nil?
        I18n.t("active_admin.producer_documents_dashboard_page.fmu_country")
      else
        r.document_type.humanize
      end
    end
    column :valid_and_expired_count
    column :valid_count
    column :expired_count
    column :pending_count
    column :invalid_count
    column :not_required_count
    column :not_provided_count
  end

  controller do
    skip_before_action :restore_search_filters
    skip_after_action :save_search_filters
    before_action :set_default_filters

    def set_default_filters
      params[:q] ||= {}
      params[:q][:required_operator_document_group_id_null] = true if params.dig(:q, :required_operator_document_group_id_eq).blank?
      params[:q][:fmu_forest_type_null] = true if params.dig(:q, :fmu_forest_type_eq).blank?
      params[:q][:document_type_null] = true if params.dig(:q, :document_type_eq).blank?
    end

    def scoped_collection
      col = if params.dig(:q, :date_gteq).present?
        super.from_date(params[:q][:date_gteq])
      else
        super
      end
      col.includes(:required_operator_document_group, country: :translations)
    end
  end
end
