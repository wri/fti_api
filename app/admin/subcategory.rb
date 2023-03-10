# frozen_string_literal: true

ActiveAdmin.register Subcategory do
  extend BackRedirectable

  menu false

  actions :all, except: [:destroy]

  config.order_clause

  controller do
    def scoped_collection
      end_of_association_chain.includes([category: :translations])
    end
  end

  permit_params :location_required, :category_id, :subcategory_type,
                translations_attributes: [:id, :locale, :name, :_destroy]

  scope I18n.t('active_admin.all'), :all, default: true
  scope I18n.t('activerecord.models.operator'), :operator
  scope I18n.t('activerecord.models.government'), :government

  filter :translations_name_eq,
         as: :select, label: I18n.t('activerecord.attributes.subcategory.name'),
         collection: -> {
           Subcategory.with_translations(I18n.locale)
             .order('subcategory_translations.name').pluck(:name)
         }
  filter :category, as: :select,
                    collection: -> { Category.with_translations(I18n.locale).order('category_translations.name') }
  filter :created_at
  filter :updated_at

  sidebar :laws, only: :show do
    sidebar = Law.where(subcategory: resource).collect do |law|
      auto_link(law, law.written_infraction&.camelize)
    end
    safe_join(sidebar, content_tag('br'))
  end

  sidebar :severities, only: :show do
    sidebar = Severity.where(subcategory: resource).collect do |sev|
      auto_link(sev, sev.level)
    end
    safe_join(sidebar, content_tag('br'))
  end

  csv do
    column :name
    column I18n.t('activerecord.models.category.one') do |s|
      s.category&.name
    end
    column :subcategory_type
    column :location_required
    column :created_at
    column :updated_at
  end

  index do
    column :name, sortable: 'subcategory_translations.name'
    column :category, sortable: 'category_translations.name'
    column :subcategory_type
    column :location_required
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.attribute_names
    edit = f.object.new_record? ? false : true
    f.inputs I18n.t('active_admin.shared.subcategory_details') do
      f.input :category,          input_html: { disabled: edit }
      f.input :subcategory_type,  input_html: { disabled: edit }
      f.input :location_required
    end

    f.inputs I18n.t('active_admin.shared.translated_fields') do
      f.translated_inputs switch_locale: false do |t|
        t.input :name
      end
    end

    f.actions
  end

  show do
    attributes_table do
      row :category
      row :subcategory_type
      row :name
      row :location_required
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
