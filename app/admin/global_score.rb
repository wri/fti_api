# frozen_string_literal: true

ActiveAdmin.register GlobalScore, as: 'Producer Documents Dashboard' do
  extend BackRedirectable
  back_redirect

  config.sort_order = 'date_desc'

  menu false

  actions :index

  filter :by_country, label: 'Country', as: :select, collection: [['All Countries', 'null']] + Country.active.map { |c| [c.name, c.id] }
  filter :by_document_group, label: 'Document Group', as: :select, collection: RequiredOperatorDocumentGroup.all
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
    (active_filters || {}).each do |filter_name, value|
      column_name, column_value = case filter_name
                                  when 'by_document_group'
                                    ['Document Group', RequiredOperatorDocumentGroup.find(value.to_i).name]
                                  when 'by_document_type'
                                    ['Document Type', value]
                                  when 'by_forest_type'
                                    ['Forest Type', Fmu.forest_types.key(value.to_i)]
                                  end
      column column_name do
        column_value
      end
    end
    column :valid, sortable: false
    column :expired, sortable: false
    column :pending, sortable: false
    column :invalid, sortable: false
    column :not_required, sortable: false
    column :not_provided, sortable: false

    grouped_sod = collection.group_by(&:date)
    hidden = { dataset: { hidden: true } }
    get_data = ->(&block) { grouped_sod.map { |date, data| { date.to_date => data.map(&block).max } }.reduce(&:merge)  }
    render partial: 'score_evolution', locals: {
        scores: [
          { name: 'Not Provided', **hidden, data: get_data.call(&:not_provided) },
          { name: 'Pending', **hidden, data: get_data.call(&:pending) },
          { name: 'Invalid', **hidden, data: get_data.call(&:invalid) },
          { name: 'Valid', data: get_data.call(&:valid) },
          { name: 'Expired', data: get_data.call(&:expired) },
          { name: 'Not Required', **hidden, data: get_data.call(&:not_required) },
        ]
      }
    panel 'Visible columns' do
      render partial: "fields", locals: {
        attributes: %w[date country valid expired invalid pending not_provided not_required],
        unchecked: %w[invalid pending not_provided not_required]
      }
    end
  end

  csv do
    column :date
    column :country_name
    column :valid
    column :expired
    column :pending
    column :invalid
    column :not_required
    column :not_provided
  end

  controller do
    helper_method :active_filters

    def index
      collection.each do |resource|
        resource.active_filters = active_filters
      end
      super
    end

    def active_filters
      params[:q]&.slice(:by_document_group, :by_document_type, :by_forest_type)&.to_unsafe_h
    end

    def scoped_collection
      super.includes(country: :translations)
    end
  end
end
