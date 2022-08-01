# frozen_string_literal: true

ActiveAdmin.register AboutPageEntry do

  extend BackRedirectable
  back_redirect

  menu false

  config.order_clause

  permit_params :position, translations_attributes: [:id, :locale, :title, :body, :_destroy]

  filter :position, as: :select
  filter :translations_title_contains, as: :select, label: 'Title',
                                       collection: -> { AboutPageEntry.with_translations(I18n.locale).pluck(:title) }
  filter :translations_body_contains, as: :select, label: 'Body',
                                      collection: -> { AboutPageEntry.with_translations(I18n.locale).pluck(:body) }

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale)
    end
  end

  csv do
    column :position
    column :title
    column :body
    column :created_at
    column :updated_at
  end

  index do
    column :position
    column :title
    # rubocop:disable Rails/OutputSafety
    column :body do |entry|
      entry.body.html_safe
    end
    # rubocop:enable Rails/OutputSafety
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'About Page Entries' do
      f.input :position
    end
    f.translated_inputs switch_locale: false do |t|
      t.input :title
      t.input :body,
              as: :quill_editor,
              input_html: {
                data: {
                  options: {
                    modules: {
                      toolbar: [['bold', 'italic', 'underline'],
                                ['link', 'video']]
                    },
                    placeholder: 'Type something...',
                    theme: 'snow'
                  }
                }
              }
    end
    f.actions
  end

  show do
    attributes_table do
      row :position
      row :title
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
