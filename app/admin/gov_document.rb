# frozen_string_literal: true

ActiveAdmin.register GovDocument do
  extend BackRedirectable
  extend Versionable

  menu false
  config.order_clause

  active_admin_paranoia

  scope_to do
    Class.new do
      def self.gov_documents
        GovDocument.unscoped
      end
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain
        .includes([[required_gov_document:
                      [required_gov_document_group: :translations, country: :translations]]])
    end
  end

  member_action :approve, method: :put do
    if resource.reason.present?
      resource.update(status: :doc_not_required)
    else
      resource.update(status: :doc_valid)
    end
    redirect_to collection_path, notice: 'Document approved'
  end

  member_action :reject, method: :put do
    resource.update(status: :doc_invalid, reason: nil)

    redirect_to collection_path, notice: 'Document rejected'
  end


  actions :all, except: [:destroy, :new]
  permit_params :status, :reason, :start_date, :expire_date,
                :uploaded_by, :link, :value, :units,
                gov_files_attributes: [:id, :attachment, :_destroy]

  index do
    bool_column :exists do |doc|
      doc.deleted_at.nil? && doc.required_gov_document.deleted_at.nil?
    end
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
    # TODO: Reactivate rubocop and fix this
    # rubocop:disable Rails/OutputSafety
    column 'Data' do |doc|
      doc.link
      "#{doc.value} #{doc.units}" if doc.value
      if doc.gov_files.any?
        links = []
        doc.gov_files.each{ |f| links << f.attachment_url }
        links.join(' ').html_safe
      end
    end
    # rubocop:enable Rails/OutputSafety
    column :user, sortable: 'users.name'
    column :expire_date
    column :start_date
    column :created_at
    column :uploaded_by
    column :reason
    column :note
    column :response_date
    column('Approve') { |doc| link_to 'Approve', approve_admin_gov_document_path(doc), method: :put }
    column('Reject') { |doc| link_to 'Reject', reject_admin_gov_document_path(doc), method: :put }
    actions
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


  scope 'Pending', :doc_pending

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
        f.has_many :gov_files do |file|
          file.input :attachment, as: :file
        end
      end
      f.input :reason
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
      if resource.required_gov_document.document_type == 'link'
        row :link
      end
      if resource.required_gov_document.document_type == 'stats'
        row :value
        row :units
      end
      if resource.required_gov_document.document_type == 'file'
        attributes_table_for resource.gov_files do
          row :attachment do |a|
            link_to a.attachment.file.identifier, a.attachment.url
          end
        end
      end
      row :reason
      row :start_date
      row :expire_date
      row :created_at
      row :updated_at
      row :deleted_at
    end
    active_admin_comments
  end
end
