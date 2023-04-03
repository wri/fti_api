# frozen_string_literal: true

ActiveAdmin.register Law do
  extend BackRedirectable

  menu false

  actions :new, :create, :show, :edit, :index, :update, :destroy

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([[country: :translations],
                                         [subcategory: :translations]])
    end
  end

  permit_params :id, :subcategory_id, :infraction, :sanctions, :min_fine, :max_fine, :currency,
                :penal_servitude, :other_penalties, :apv, :written_infraction, :country_id

  filter :country, as: :select,
                   collection: -> { Country.joins(:laws).with_translations(I18n.locale).order('country_translations.name') }
  filter :subcategory, as: :select,
                       collection: -> { Subcategory.joins(:laws).with_translations(I18n.locale).order('subcategory_translations.name') }
  filter :written_infraction, label: proc { I18n.t('active_admin.laws_page.written_infraction') }, as: :select
  filter :infraction, label: proc { I18n.t('active_admin.laws_page.infraction') }, as: :select
  filter :sanctions, label: proc { I18n.t('active_admin.laws_page.sanctions') }, as: :select
  filter :max_fine, label: proc { I18n.t('active_admin.laws_page.max_fine') }
  filter :min_fine, label: proc { I18n.t('active_admin.laws_page.min_fine') }

  csv do
    column :country do |l|
      l.country&.name
    end
    column :subcategory do |l|
      l.subcategory&.name
    end
    column I18n.t('active_admin.laws_page.written_infraction') do |l|
      l.written_infraction
    end
    column I18n.t('active_admin.laws_page.infraction') do |l|
      l.infraction
    end
    column I18n.t('active_admin.laws_page.sanctions') do |l|
      l.sanctions
    end
    column :min_fine
    column :max_fine
    column :currency
    column :penal_servitude
    column :other_penalties
    column :apv
    column :created_at
    column :updated_at
  end

  index do
    column :country, sortable: 'country_translations.name'
    column :subcategory, sortable: 'subcategory_translations.name'
    column I18n.t('active_admin.laws_page.written_infraction'), :written_infraction, sortable: true
    column I18n.t('active_admin.laws_page.infraction'), :infraction, sortable: true
    column I18n.t('active_admin.laws_page.sanctions'), :sanctions, sortable: true
    column I18n.t('active_admin.laws_page.min_fine'), :min_fine, sortable: true
    column I18n.t('active_admin.laws_page.max_fine'), :max_fine, sortable: true
    column :currency
    column :penal_servitude, sortable: true
    column :other_penalties, sortable: true
    column I18n.t('active_admin.laws_page.indicator_apv'), :apv, sortable: true
    column :created_at, sortable: true
    column :updated_at, sortable: true

    actions

  end

  form do |f|
    f.semantic_errors *f.object.errors.attribute_names
    f.inputs I18n.t('active_admin.laws_page.law_details') do
      if f.object.new_record?
        f.input :country
        f.input :subcategory, as: :select,
                              collection: Subcategory.operator.with_translations(I18n.locale).order(:name)
      else
        f.input :country, input_html: { disabled: true }
        f.input :subcategory, input_html: { disabled: true }
      end

      f.input :written_infraction, label: I18n.t('active_admin.laws_page.written_infraction')
      f.input :infraction,         label: I18n.t('active_admin.laws_page.infraction')
      f.input :sanctions,          label: I18n.t('active_admin.laws_page.sanctions')
      f.input :min_fine,           label: I18n.t('active_admin.laws_page.min_fine')
      f.input :max_fine,           label: I18n.t('active_admin.laws_page.max_fine')
      f.input :currency
      f.input :penal_servitude
      f.input :other_penalties
      f.input :apv, label: I18n.t('active_admin.laws_page.indicator_apv')

      f.actions
    end
  end
end
