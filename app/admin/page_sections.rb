# frozen_string_literal: true

ActiveAdmin.register PageSection do
  belongs_to :page

  menu false

  config.batch_actions = false
  actions :all, except: [:index]

  breadcrumb do
    [link_to(Page.model_name.human(count: 2), admin_pages_path), link_to(parent.title, admin_page_path(parent))]
  end

  permit_params :position, :code, translations_attributes: [:id, :locale, :title, :body, :_destroy]

  controller do
    def method_for_association_chain
      :sections
    end

    def create
      create! { parent_path }
    end

    def update
      update! { parent_path }
    end

    def destroy
      destroy! { parent_path }
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Section" do
      f.input :position, hint: "leaving empty will assign last position"
      f.input :code, as: :select, collection: PageSection::CODES, include_blank: "None",
        hint: "Renders a portal component after the section text. Title and body are optional when set"
    end
    f.translated_inputs "Translations", switch_locale: false, available_locales: f.object.page.available_in_languages&.map(&:to_sym) || I18n.available_locales do |t|
      t.input :title
      t.input :body, as: :html_editor
    end
    f.actions do
      f.action :submit
      f.cancel_link admin_page_path(f.object.page)
    end
  end

  show do
    attributes_table do
      row :page
      row :position
      translated_row :title
      row :code
      translated_row(:body) { |section| sanitize(section.body) }
      row :created_at
      row :updated_at
    end
  end
end
