# frozen_string_literal: true

ActiveAdmin.register GovDocument do
  extend BackRedirectable
  extend Versionable

  menu false
  config.order_clause

  active_admin_paranoia

  controller do
    def scoped_collection
      end_of_association_chain
        .includes([[required_gov_document:
                      [required_gov_document_group: :translations, country: :translations]]])
    end
  end

  member_action :approve, method: :put do
    resource.update(status: :doc_valid)
    redirect_to collection_path, notice: 'Document approved'
  end

  member_action :reject, method: :put do
    resource.update(status: :doc_invalid)
    redirect_to collection_path, notice: 'Document rejected'
  end


  actions :all, except: [:destroy, :new]
  permit_params :status, :start_date, :expire_date, :attachment,
                :uploaded_by, :link, :value, :units

  config.clear_action_items!

  action_item :edit_gov_document, only: [:show] do
    link_to 'Edit Document', edit_resource_path(resource)
  end

  scope 'Pending', :doc_pending

  index do
    tag_column :status
    column :id
    column :country do |doc|
      doc.required_gov_document.country
    end
    column 'Required Document', :required_gov_document, sortable: 'required_gov_documents.name' do |doc|
      if doc.required_gov_document.present?
        link_to doc.required_gov_document.name, admin_required_gov_document_path(doc.required_gov_document)
      else
        RequiredGovDocument.unscoped.find(doc.required_gov_document_id).name
      end
    end
    column 'Data' do |doc|
      doc.link
      "#{doc.value} #{doc.units}" if doc.value
      link_to doc.attachment.file.identifier, doc.attachment.url if doc.attachment.present?
    end
    column :user, sortable: 'users.name'
    column :start_date
    column :expire_date
    column :created_at

    if current_scope.id == 'recycle_bin'
      column :deleted_at
    else
      column('Approve') do |doc|
        link_to 'Approve', approve_admin_gov_document_path(doc), method: :put if %w[doc_pending doc_invalid].include? doc.status
      end
      column('Reject') do |doc|
        link_to 'Reject', reject_admin_gov_document_path(doc), method: :put if %w[doc_pending doc_valid].include? doc.status
      end

      actions defaults: false do |doc|
        item 'View', resource_path(doc)
        item 'Edit', edit_resource_path(doc)
      end
    end
  end

  filter :id, as: :select
  filter :required_gov_document
  filter :required_gov_document_country_id,
         label: 'Country',
         as: :select,
         collection: -> { Country.with_translations(I18n.locale).joins(:required_gov_documents).distinct.order('country_translations.name') }
  filter :status, as: :select, collection: -> { GovDocument.statuses }
  filter :required_gov_document_document_type, label: 'Type', as: :select, collection: -> { RequiredGovDocument.document_types }
  filter :updated_at

  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Government Document Details' do
      f.input :country, as: :string,
                        input_html: { disabled: true, value: resource&.required_gov_document&.country&.name }
      f.input :required_gov_document, input_html: { disabled: true }
      f.input :uploaded_by
      f.input :status, include_blank: false
      f.input :document_type, as: :string,
                              input_html: { disabled: true, value: resource&.required_gov_document&.document_type }
      if resource.required_gov_document.document_type == 'link'
        f.input :link
      end
      if resource.required_gov_document.document_type == 'stats'
        f.input :value
        f.input :units
      end
      if resource.required_gov_document.document_type == 'file'
        f.input :attachment, as: :file, hint: preview_file_tag(f.object.attachment)
      end
      f.input :expire_date, as: :date_picker
      f.input :start_date, as: :date_picker
    end
    f.actions
  end

  show title: proc{ "#{resource.required_gov_document.country.name} - #{resource.required_gov_document.name}" } do
    attributes_table do
      tag_row :status
      row :required_gov_document
      row :country do |doc|
        doc.required_gov_document.country.name
      end
      row :uploaded_by
      row :user
      if resource.required_gov_document.document_type == 'link'
        row :link
      end
      if resource.required_gov_document.document_type == 'stats'
        row :value
        row :units
      end
      if resource.required_gov_document.document_type == 'file'
        row :attachment do |doc|
          link_to doc.attachment.file.identifier, doc.attachment.url if doc.attachment.present?
        end
      end
      row :start_date
      row :expire_date
      row :created_at
      row :updated_at
      row :deleted_at
    end
    active_admin_comments
  end
end
