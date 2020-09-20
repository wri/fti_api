# frozen_string_literal: true

ActiveAdmin.register Operator, as: 'Producer' do
  extend BackRedirectable
  back_redirect

  extend Versionable
  versionate

  menu false

  config.order_clause

  actions :all
  permit_params :name, :fa_id, :operator_type, :country_id, :details, :concession, :is_active,
                :logo, :delete_logo, fmu_ids: [],
                                     translations_attributes: [:id, :locale, :name, :details, :_destroy]

  member_action :activate, method: :put do
    resource.update(is_active: true)
    redirect_to collection_path, notice: 'Operator activated'
  end

  csv do
    column :is_active
    column :country do |operator|
      operator.country.name rescue nil
    end
    column :fa_id
    column :name
    column :concession
    column :score_absolute do |operator|
      "#{'%.2f' % operator.score_absolute}" rescue nil
    end
    column :obs_per_visit
    column '% Docs' do |operator|
      operator.score_operator_document&.all
    end
  end

  index do
    column 'Active?', :is_active
    column :id
    column :country, sortable: 'country_translations.name'
    column 'FA UUID', :fa_id
    column :name, sortable: 'operator_translations.name'
    column :concession, sortable: true
    column 'Score', :score_absolute, sortable: 'score_absolute' do |operator|
      "#{'%.2f' % operator.score_absolute}" rescue nil
    end
    column 'Obs/Visit', :obs_per_visit, sortable: true
    column '% Docs', :percentage_valid_documents_all, sortable: true do |operator|
      operator.score_operator_document&.all
    end
    column('Actions') do |operator|
      unless operator.is_active
        a 'Activate', href: activate_admin_producer_path(operator),
                      'data-method': :put, 'data-confirm': "Are you sure you want to ACTIVATE the operator #{operator.name}?"
      end
    end

    actions
  end

  scope :all, default: true
  scope :active
  scope :inactive

  filter :country, as: :select,
                   collection: -> { Country.joins(:operators).with_translations(I18n.locale).order('country_translations.name') }
  filter :id,
         as: :select, label: 'Name',
         collection: Operator.with_translations(I18n.locale)
                         .order('operator_translations.name').pluck(:name, :id)
  filter :concession, as: :select
  filter :score_absolute, label: 'Obs/Visit'

  sidebar 'Fmus', only: :show do
    attributes_table_for resource do
      ul do
        resource.fmus.collect do |fmu|
          li link_to(fmu.name, admin_fmu_path(fmu.id))
        end
      end
    end
  end

  sidebar 'Sawmills', only: :show do
    attributes_table_for resource do
      ul do
        resource.sawmills.collect do |sawmill|
          li link_to(sawmill.name, admin_sawmill_path(sawmill.id))
        end
      end
    end
  end

  sidebar 'Valid Documents', only: :show, if: proc{ resource.operator_documents.where(status: 'doc_valid').any? } do
    table_for resource.operator_documents.where(status: 'doc_valid').collect do |od|
      column('') { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
    end
  end

  sidebar 'Pending Documents', only: :show, if: proc{ resource.operator_documents.where(status: 'doc_pending').any? } do
    table_for resource.operator_documents.where(status: 'doc_pending').collect do |od|
      column('') { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
    end
  end

  sidebar 'Invalid Documents', only: :show,
                               if: proc{ resource.operator_documents.where(status: %w(doc_not_provided doc_invalid doc_expired)).any? } do
    table_for resource.operator_documents.where(status: %w(doc_not_provided doc_invalid doc_expired)).collect do |od|
      column('') { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
    end
  end


  form do |f|
    edit = f.object.new_record? ? false : true
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Operator Details' do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
        t.input :details
      end
      f.input :fa_id, as: :string, label: 'Forest Atlas UUID'
      f.input :operator_type, as: :select,
                              collection: ['Logging company', 'Artisanal', 'Community forest', 'Estate',
                                           'Industrial agriculture', 'Mining company',
                                           'Sawmill', 'Other', 'Unknown']
      f.input :country, input_html: { disabled: edit }
      f.input :concession
      f.input :logo, as: :file, hint: f.template.image_tag(f.object.logo.url(:thumbnail))
      if f.object.logo.present?
        f.input :delete_logo, as: :boolean, required: false, label: 'Remove logo'
      end
      available_fmus = Fmu.filter_by_free
      if edit
        available_fmus = []
        Fmu.filter_by_free.find_each{ |x| available_fmus << x }
        f.object.fmus.find_each{ |x| available_fmus << x }
        f.input :fmus, collection: available_fmus
      else
        f.input :fmus, collection: available_fmus
      end
      f.input :is_active
    end
    f.actions
  end

  show do
    attributes_table do
      row :is_active
      row :name
      row :operator_type
      row :fa_id
      row :details
      row :country
      image_row :logo
      row :address
      row :website
      row :fmus
      row :percentage_valid_documents_all do |operator|
        operator.score_operator_document&.all
      end
      row :obs_per_visit
      row :score_absolute
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end



  controller do
    def scoped_collection
      end_of_association_chain.with_translations.includes(country: :translations)
    end
  end
end
