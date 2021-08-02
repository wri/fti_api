# frozen_string_literal: true

ActiveAdmin.register OperatorDocumentStatistic, as: 'Producer Documents Alternative Dashboard' do
  extend BackRedirectable
  back_redirect

  config.sort_order = 'date_desc'
  config.per_page = [30, 50, 100]

  menu false

  actions :index

  filter :by_country, label: 'Country', as: :select, collection: [['All Countries', 'null']] + Country.active.map { |c| [c.name, c.id] }
  filter :required_operator_document_group, as: :select, collection: RequiredOperatorDocumentGroup.without_publication_authorization
  filter :document_type_eq, label: 'Document Type', as: :select, collection: [['FMU', :fmu], ['Country', :country]]
  filter :fmu_forest_type_eq, label: 'Forest Type', as: :select, collection: Fmu::FOREST_TYPES.map { |ft| [ft.last[:label], ft.last[:index]] }
  filter :date

  index title: 'Producer Documents Dashboard' do
    column :date do |resource|
      resource.date.to_date
    end
    column :country do |resource|
      if resource.country.nil?
        'All Countries'
      else
        link_to resource.country.name, admin_country_path(resource.country)
      end
    end
    column :required_operator_document_group do |r|
      if r.required_operator_document_group.nil?
        'All Groups'
      else
        link_to r.required_operator_document_group.name, admin_required_operator_document_group_path(r.required_operator_document_group)
      end
    end
    column :fmu_forest_type do |r|
      if r.fmu_forest_type.nil?
        'All Forest Types'
      else
        Fmu.forest_types.key(r.fmu_forest_type)
      end
    end
    column :document_type do |r|
      if r.document_type.nil?
        'Fmu/Country'
      else
        r.document_type.humanize
      end
    end
    column 'Valid & Expired', sortable: false, &:valid_and_expired_count
    column :valid, sortable: false, &:valid_count
    column :expired, sortable: false, &:expired_count
    column :pending, sortable: false, &:pending_count
    column :invalid, sortable: false, &:invalid_count
    column :not_required, sortable: false, &:not_required_count
    column :not_provided, sortable: false, &:not_provided_count

    show_on_chart = if params.dig(:q, :by_country).present?
                      collection
                    else
                      collection.select { |r| r.country_id.nil? }
                    end
    grouped_sod = show_on_chart.group_by(&:date)
    hidden = { dataset: { hidden: true } }
    get_data = ->(&block) { grouped_sod.map { |date, data| { date.to_date => data.map(&block).max } }.reduce(&:merge)  }
    render partial: 'score_evolution', locals: {
        scores: [
          { name: 'Not Provided', **hidden, data: get_data.call(&:not_provided_count) },
          { name: 'Pending', **hidden, data: get_data.call(&:pending_count) },
          { name: 'Invalid', **hidden, data: get_data.call(&:invalid_count) },
          { name: 'Valid & Expired', data: get_data.call(&:valid_and_expired_count) },
          { name: 'Valid', data: get_data.call(&:valid_count) },
          { name: 'Expired', data: get_data.call(&:expired_count) },
          { name: 'Not Required', **hidden, data: get_data.call(&:not_required_count) },
        ]
      }

    panel 'Visible columns' do
      render partial: "fields", locals: {
        attributes: %w[date country required_operator_document_group fmu_forest_type document_type valid_&_expired valid expired invalid pending not_provided not_required],
        unchecked: %w[required_operator_document_group fmu_forest_type document_type invalid pending not_provided not_required]
      }
    end
  end

  csv do
    column :date do |resource|
      resource.date.strftime('%d/%m/%Y')
    end
    column :country, &:country_name
    column :required_operator_document_group do |r|
      if r.required_operator_document_group.nil?
        'All Groups'
      else
        r.required_operator_document_group.name
      end
    end
    column :fmu_forest_type do |r|
      if r.fmu_forest_type.nil?
        'All Forest Types'
      else
        Fmu.forest_types.key(r.fmu_forest_type)
      end
    end
    column :document_type do |r|
      if r.document_type.nil?
        'Fmu/Country'
      else
        r.document_type.humanize
      end
    end
    column 'Valid & Expired', &:valid_and_expired_count
    column :valid, &:valid_count
    column :expired, &:expired_count
    column :pending, &:pending_count
    column :invalid, &:invalid_count
    column :not_required, &:not_required_count
    column :not_provided, &:not_provided_count
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
      super.includes(:required_operator_document_group, country: :translations)
    end
  end
end
