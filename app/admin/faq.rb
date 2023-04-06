# frozen_string_literal: true

ActiveAdmin.register Faq do
  extend BackRedirectable

  menu false

  config.order_clause

  permit_params :position, translations_attributes: [:id, :locale, :question, :answer, :_destroy]

  filter :position, as: :select
  filter :translations_question_contains, as: :select, label: proc { I18n.t("activerecord.attributes.faq.question") },
    collection: -> { Faq.with_translations(I18n.locale).pluck(:question) }
  filter :translations_answer_contains, as: :select, label: proc { I18n.t("activerecord.attributes.faq.answer") },
    collection: -> { Faq.with_translations(I18n.locale).pluck(:answer) }

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale)
    end
  end

  csv do
    column :position
    column :question
    column :answer
    column :created_at
    column :updated_at
  end

  index do
    column :position
    column :question
    column :answer
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "FAQ Details" do
      f.input :position
    end
    f.translated_inputs switch_locale: false do |t|
      t.input :question
      t.input :answer, as: :html_editor
    end
    f.actions
  end

  show do
    attributes_table do
      row :position
      row :question
      row :answer
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
