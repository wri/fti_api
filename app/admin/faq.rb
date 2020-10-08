# frozen_string_literal: true

ActiveAdmin.register Faq do
  extend BackRedirectable
  back_redirect

  menu false

  config.order_clause


  permit_params :position, :image, translations_attributes: [:id, :locale, :question, :answer, :_destroy]

  filter :position, as: :select
  filter :translations_question_contains, as: :select, label: 'Question',
                                          collection: Faq.with_translations(I18n.locale).pluck(:question)
  filter :translations_answer_contains, as: :select, label: 'Answer',
                                        collection: Faq.with_translations(I18n.locale).pluck(:answer)

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
    image_column :image
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'FAQ Details' do
      f.input :position
      f.input :image, as: :file, hint: image_tag(f.object.image.url(:thumbnail))
      if f.object.image.present?
        f.input :delete_image, as: :boolean, required: false, label: 'Remove image'
      end
    end
    f.translated_inputs switch_locale: false do |t|
      t.input :question
      t.input :answer,
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
      row :question
      row :answer
      image_row :image
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

end
