# frozen_string_literal: true

ActiveAdmin.register Law do
  extend BackRedirectable

  menu false

  actions :new, :create, :show, :edit, :index, :update, :destroy

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([[country: :translations], [subcategory: :translations]])
    end
  end

  permit_params :id, :subcategory_id, :infraction, :sanctions, :min_fine, :max_fine, :currency,
    :penal_servitude, :other_penalties, :apv, :written_infraction, :country_id

  filter :country, as: :select, collection: -> { Country.joins(:laws).with_translations(I18n.locale).by_name_asc.distinct }
  filter :subcategory, as: :select, collection: -> { Subcategory.joins(:laws).with_translations(I18n.locale).by_name_asc.distinct }
  filter :written_infraction_cont, label: proc { Law.human_attribute_name(:written_infraction) }
  filter :infraction_cont, label: proc { Law.human_attribute_name(:infraction) }
  filter :sanctions_cont, label: proc { Law.human_attribute_name(:sanctions) }
  filter :max_fine, label: proc { Law.human_attribute_name(:max_fine) }
  filter :min_fine, label: proc { Law.human_attribute_name(:min_fine) }

  dependent_filters do
    {
      country_id: {
        subcategory_id: Law.distinct.pluck(:country_id, :subcategory_id)
      }
    }
  end

  csv do
    column :country do |l|
      l.country&.name
    end
    column :subcategory do |l|
      l.subcategory&.name
    end
    column :written_infraction
    column :infraction
    column :sanctions
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
    column :country, sortable: "country_translations.name"
    column :subcategory, sortable: "subcategory_translations.name"
    column :written_infraction, sortable: true
    column :infraction, sortable: true
    column :sanctions, sortable: true
    column :min_fine, sortable: true
    column :max_fine, sortable: true
    column :currency
    column :penal_servitude, sortable: true
    column :other_penalties, sortable: true
    column :apv, sortable: true
    column :created_at, sortable: true
    column :updated_at, sortable: true

    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("active_admin.shared.law_details") do
      if f.object.new_record?
        f.input :country
        f.input :subcategory, as: :select,
          collection: Subcategory.operator.with_translations(I18n.locale).order(:name)
      else
        f.input :country, input_html: {disabled: true}
        f.input :subcategory, input_html: {disabled: true}
      end

      f.input :written_infraction
      f.input :infraction
      f.input :sanctions
      f.input :min_fine
      f.input :max_fine
      f.input :currency
      f.input :penal_servitude
      f.input :other_penalties
      f.input :apv

      f.actions
    end
  end
end
