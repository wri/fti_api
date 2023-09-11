# frozen_string_literal: true

ActiveAdmin.register Page do
  extend BackRedirectable

  menu false

  permit_params :slug, available_in_languages: [], translations_attributes: [:id, :locale, :title, :body, :_destroy]

  filter :slug

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale)
    end
  end

  csv do
    column :title
    column :slug
    column :created_at
    column :updated_at
  end

  index do
    column :title
    column :slug
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :slug
      f.input :available_in_languages, collection: I18n.available_locales, multiple: true, hint: "Leave empty to make page available in all languages"
    end
    f.translated_inputs "Translations", switch_locale: false, available_locales: f.object.available_in_languages&.map(&:to_sym) || I18n.available_locales do |t|
      t.input :title
      t.input :body, as: :html_editor, input_html: {class: "ql-editor-big"}
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :slug
      row :available_in_languages
      # rubocop:disable Rails/OutputSafety
      row :body do |entry|
        entry.body.html_safe
      end
      # rubocop:enable Rails/OutputSafety
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
