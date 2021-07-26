# frozen_string_literal: true

ActiveAdmin.register GlobalScore, as: 'Producer Documents Dashboard' do
  extend BackRedirectable
  back_redirect

  menu false

  actions :index, :show

  filter :country
  filter :by_document_group, as: :select, collection: RequiredOperatorDocumentGroup.all
  filter :by_document_type, as: :select, collection: [['FMU', :fmu], ['Country', :country]]
  filter :by_fmu_type, as: :select, collection: Fmu::FOREST_TYPES.map { |ft| [ft.last[:label], ft.last[:index]] }
  filter :date
  filter :updated_at
  filter :created_at

  index title: 'Producer Documents Dashboard' do
    column :date
    column :country do |resource|
      if resource.country.nil?
        'Total'
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
    column :created_at
    column :updated_at
    actions

    grouped_sod = GlobalScore.group_by_day(:date, series: false)
    render partial: 'score_evolution', locals: {
        scores: [
            { name: 'all', data: grouped_sod.maximum(:total_required) },
            { name: 'Not Provided', data: grouped_sod.maximum("general_status->>'doc_not_provided'") },
            { name: 'Pending', data: grouped_sod.maximum("general_status->>'doc_pending'") },
            { name: 'Invalid', data: grouped_sod.maximum("general_status->>'doc_invalid'") },
            { name: 'Valid', data: grouped_sod.maximum("general_status->>'doc_valid'") },
            { name: 'Expired', data: grouped_sod.maximum("general_status->>'doc_expired'") },
            { name: 'Not Required', data: grouped_sod.maximum("general_status->>'doc_not_required'") },
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
      params[:q]&.permit(:by_document_group, :by_document_type).to_h
    end
  end
end
