# frozen_string_literal: true

ActiveAdmin.register Newsletter do
  extend BackRedirectable

  menu false

  permit_params :date, :attachment, :image, :force_translations_from, translations_attributes: [:id, :locale, :title, :short_description, :_destroy]

  controller do
    def scoped_collection
      end_of_association_chain.with_translations(I18n.locale)
    end
  end

  member_action :force_translations do
    translate_from = params[:translate_from] || I18n.locale
    TranslationJob.perform_later(resource, translate_from)
    redirect_to admin_newsletter_path(resource), notice: I18n.t("active_admin.shared.translating_entity")
  end

  action_item :force_translations, only: :show do
    dropdown_menu I18n.t("active_admin.shared.force_translations") do
      I18n.available_locales.each do |locale|
        item locale, force_translations_admin_newsletter_path(newsletter, translate_from: locale)
      end
    end
  end

  csv do
    column :title
    column :date
    column :short_description
    column :created_at
    column :updated_at
  end

  index do
    column :title
    column :date
    column :short_description
    column I18n.t("active_admin.operator_documents_page.attachment") do |n|
      link_to n.attachment.identifier, n.attachment.url if n.attachment.present?
    end
    column :created_at
    column :updated_at

    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs I18n.t("active_admin.details", model: "newsletter") do
      f.input :date, as: :date_picker
      f.input :attachment, as: :file, hint: f.object&.attachment&.file&.filename
      f.input :image, as: :file, hint: f.object.image.present? && image_tag(f.object.image.url(:thumbnail))
    end
    f.inputs I18n.t("active_admin.shared.translated_fields") do
      f.input :force_translations_from, label: I18n.t("active_admin.shared.translate_from"),
        as: :select,
        collection: I18n.available_locales,
        include_blank: true,
        hint: I18n.t("active_admin.shared.translate_from_hint"),
        input_html: {class: "translate_from"}
      f.translated_inputs "Translations", switch_locale: false do |t|
        t.input :title
        t.input :title_translated_from, input_html: {disabled: true}
        t.input :short_description
        t.input :short_description_translated_from, input_html: {disabled: true}
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :title
      row :date
      row :short_description
      row :image do |r|
        image_tag r.image.url(:thumbnail) if r.image.present?
      end
      row :attachment do |r|
        link_to r.attachment.file.identifier, r.attachment.url if r.attachment.present?
      end
      row :created_at
      row :updated_at
    end
  end
end
