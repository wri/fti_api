# frozen_string_literal: true

ActiveAdmin.register GlobalScore, as: 'Producer Documents Dashboard' do
  extend BackRedirectable
  back_redirect

  config.sort_order = 'date_desc'

  menu false

  actions :index

  filter :by_country, label: 'Country', as: :select, collection: [['All Countries', 'null']] + Country.active.map { |c| [c.name, c.id] }
  filter :by_document_group, label: 'Document Group', as: :select, collection: RequiredOperatorDocumentGroup.without_publication_authorization
  filter :by_document_type, label: 'Document Type', as: :select, collection: [['FMU', :fmu], ['Country', :country]]
  filter :by_forest_type, label: 'Forest Type', as: :select, collection: Fmu::FOREST_TYPES.map { |ft| [ft.last[:label], ft.last[:index]] }
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
    active_filter_columns.each do |name, value|
      column(name) { value }
    end
    column 'Valid & Expired', sortable: false, &:valid_and_expired_count
    column :valid, sortable: false, &:valid_count
    column :expired, sortable: false, &:expired_count
    column :pending, sortable: false, &:pending_count
    column :invalid, sortable: false, &:invalid_count
    column :not_required, sortable: false, &:not_required_count
    column :not_provided, sortable: false, &:not_provided_count

    grouped_sod = collection.group_by(&:date)
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
        attributes: %w[date country valid_&_expired valid expired invalid pending not_provided not_required],
        unchecked: %w[invalid pending not_provided not_required]
      }
    end
  end

  csv do
    column :date do |resource|
      resource.date.strftime('%d/%m/%Y')
    end
    column :country, &:country_name
    active_filter_columns.each do |name, value|
      column(name) { value }
    end
    column :valid_&_expired, &:valid_and_expired_count
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

    helper_method :active_filter_columns

    def index
      collection.each do |resource|
        resource.active_filters = active_filters
      end
      super
    end

    def active_filters
      params[:q]&.slice(:by_document_group, :by_document_type, :by_forest_type)&.to_unsafe_h
    end

    def active_filter_columns
      (active_filters || {}).map do |filter_name, value|
        case filter_name
        when 'by_document_group'
          ['Document Group', RequiredOperatorDocumentGroup.find(value.to_i).name]
        when 'by_document_type'
          ['Document Type', value]
        when 'by_forest_type'
          ['Forest Type', Fmu.forest_types.key(value.to_i)]
        end
      end
    end

    def scoped_collection
      super.includes(country: :translations)
    end
  end
end
