# frozen_string_literal: true

ActiveAdmin.register NewGlobalScore, as: 'Producer Documents Alternative Dashboard' do
  extend BackRedirectable
  back_redirect

  config.sort_order = 'date_desc'

  menu false

  actions :index

  filter :country_id_null, label: 'Only Show Total for Countries', as: :boolean
  filter :country, as: :select, collection: Country.active
  filter :by_country, label: 'Country 2', as: :select, multiple: true, collection: [['All Countries', 'null']] + Country.active.map { |c| [c.name, c.id] }
  filter :required_operator_document_group
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
    column 'Valid', :doc_valid, sortable: false
    column 'Expired', :doc_expired, sortable: false
    column 'Pending', :doc_pending, sortable: false
    column 'Invalid', :doc_invalid, sortable: false
    column 'Not Required', :doc_not_required, sortable: false
    column 'Not Provided', :doc_not_provided, sortable: false

    # grouped_sod = collection.group_by(&:date)
    # hidden = { dataset: { hidden: true } }
    # get_data = ->(&block) { grouped_sod.map { |date, data| { date.to_date => data.map(&block).max } }.reduce(&:merge)  }
    # render partial: 'score_evolution', locals: {
    #     scores: [
    #       { name: 'Not Provided', **hidden, data: get_data.call(&:doc_not_provided) },
    #       { name: 'Pending', **hidden, data: get_data.call(&:doc_pending) },
    #       { name: 'Invalid', **hidden, data: get_data.call(&:doc_invalid) },
    #       { name: 'Valid', data: get_data.call(&:doc_valid) },
    #       { name: 'Expired', data: get_data.call(&:doc_expired) },
    #       { name: 'Not Required', **hidden, data: get_data.call(&:doc_not_required) },
    #     ]
    #   }
    panel 'Visible columns' do
      render partial: "fields", locals: { attributes: %w[date country valid expired invalid pending not_provided not_required] }
    end
  end

  csv do
    column :date
    column :required_operator_document_group
    column :fmu_forest_type do |type|
      Fmu.forest_types.key(type)
    end
    column :document_type
    column :country_name
    column :doc_valid
    column :doc_expired
    column :doc_pending
    column :doc_invalid
    column :doc_not_required
    column :doc_not_provided
  end

  controller do
    def scoped_collection
      super.includes(:required_operator_document_group, country: :translations)
    end
  end
end
