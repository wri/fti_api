# frozen_string_literal: true

ActiveAdmin.register GlobalScore, as: 'Producer Documents Dashboard' do
  extend BackRedirectable
  back_redirect

  menu false

  actions :index

  filter :country
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
    column :valid, sortable: false
    column :expired, sortable: false
    column :pending, sortable: false
    column :invalid, sortable: false
    column :not_required, sortable: false
    column :not_provided, sortable: false

    grouped_sod = collection.group_by(&:date)
    render partial: 'score_evolution', locals: {
        scores: [
          { name: 'Not Provided', data: grouped_sod.map { |date, data| { date => data.map(&:not_provided).max } }.reduce(&:merge) },
          { name: 'Pending', data: grouped_sod.map { |date, data| { date => data.map(&:pending).max } }.reduce(&:merge) },
          { name: 'Invalid', data: grouped_sod.map { |date, data| { date => data.map(&:invalid).max } }.reduce(&:merge) },
          { name: 'Valid', data: grouped_sod.map { |date, data| { date => data.map(&:valid).max } }.reduce(&:merge) },
          { name: 'Expired', data: grouped_sod.map { |date, data| { date => data.map(&:expired).max } }.reduce(&:merge) },
          { name: 'Not Required', data: grouped_sod.map { |date, data| { date => data.map(&:not_required).max } }.reduce(&:merge) },
        ]
      }
    panel 'Visible columns' do
      render partial: "fields", locals: { attributes: %w[date country valid expired invalid pending not_provided not_required] }
    end
  end

  controller do
    def index
      collection.each do |resource|
        resource.active_filters = active_filters
      end
      super
    end

    def active_filters
      params[:q]&.permit(:by_document_group, :by_document_type, :by_forest_type).to_h
    end
  end
end
