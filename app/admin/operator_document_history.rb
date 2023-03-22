# frozen_string_literal: true

ActiveAdmin.register OperatorDocumentHistory do
  extend BackRedirectable

  menu false
  config.order_clause

  scope I18n.t('active_admin.operator_documents_page.with_deleted'), :with_deleted, default: true

  sidebar I18n.t('active_admin.operator_documents_page.annexes'), only: :show do
    attributes_table_for resource do
      ul do
        resource.operator_document_annexes.collect do |annex|
          li link_to(annex.name, admin_operator_document_annex_path(annex.id))
        end
      end
    end
  end

  actions :index, :show

  csv do
    column I18n.t('active_admin.required_operator_document_page.exists') do |o|
      o.deleted_at.nil? && o.required_operator_document.deleted_at.nil?
    end
    column :status
    column :id
    column :operator_document_updated_at
    column :operator_document do |o|
      o.operator_document&.required_operator_document&.name
    end
    column I18n.t('activerecord.models.country.one') do |o|
      o.required_operator_document.country&.name
    end
    column :Type do |o|
      if o.required_operator_document.present?
        o.required_operator_document.type == 'RequiredOperatorDocumentFmu' ? 'Fmu' : 'Operator'
      else
        RequiredOperatorDocument.unscoped.find(o.required_operator_document_id).type
      end
    end
    column :operator do |o|
      o.operator&.name
    end
    column :fmu do |o|
      o.fmu&.name
    end
    column I18n.t('active_admin.operator_documents_page.legal_category') do |o|
      if o.required_operator_document.present?
        o.required_operator_document.required_operator_document_group.name
      else
        RequiredOperatorDocument.unscoped.find(o.required_operator_document_id).required_operator_document_group.name
      end
    end
    column :user do |o|
      o.user&.name
    end
    column :expire_date
    column :start_date
    column :operator_document_created_at
    column :uploaded_by
    column :attachment do |o|
      o&.document_file&.attachment&.filename
    end
    # TODO: Reactivate rubocop and fix this
    # rubocop:disable Rails/OutputSafety
    column I18n.t('active_admin.operator_documents_page.annexes') do |o|
      links = []
      o.operator_document_annexes.each { |a| links << a.name }
      links.join(' ').html_safe
    end
    # rubocop:enable Rails/OutputSafety
    column :reason
    column :note
    column :response_date
  end

  index do
    render partial: 'dependent_filters', locals: {
      filter: {
        required_operator_document_country_id: {
          operator_document_required_operator_document_id: HashHelper.aggregate(RequiredOperatorDocument.pluck(:country_id, :id)),
          operator_id: HashHelper.aggregate(Operator.pluck(:country_id, :id))
        },
        operator_id: {
          fmu_id: HashHelper.aggregate(FmuOperator.where(current: true).pluck(:operator_id, :fmu_id))
        }
      }
    }

    column :public
    tag_column :status
    column :id
    column :operator_document do |od|
      if od.operator_document.present?
        link_to od.operator_document&.required_operator_document&.name, admin_operator_document_path(od.operator_document&.id)
      else
        od.operator_document&.required_operator_document&.name
      end
    end
    column :operator_document_updated_at
    column :country do |od|
      od.required_operator_document&.country
    end
    column I18n.t('activerecord.models.required_operator_document'), :required_operator_document, sortable: 'required_operator_document_id' do |od|
      if od.required_operator_document.present?
        link_to od.required_operator_document.name, admin_required_operator_document_path(od.required_operator_document)
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).name
      end
    end
    column :Type, sortable: false do |od|
      if od.required_operator_document.present?
        od.required_operator_document.type == 'RequiredOperatorDocumentFmu' ? 'Fmu' : 'Operator'
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).type
      end
    end
    column :operator, sortable: false
    column :fmu, sortable: false
    column I18n.t('active_admin.operator_documents_page.legal_category') do |od|
      if od.required_operator_document.present?
        od.required_operator_document.required_operator_document_group.name
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).required_operator_document_group.name
      end
    end
    column :user, sortable: false
    column :expire_date
    column :start_date
    column :operator_document_created_at
    column :deleted_at
    column :uploaded_by
    column :source
    column I18n.t('active_admin.operator_documents_page.attachment') do |od|
      if od&.document_file&.attachment
        link_to od.document_file.attachment.identifier, od.document_file.attachment.url
      end
    end
    # TODO: Reactivate rubocop and fix this
    # rubocop:disable Rails/OutputSafety
    column I18n.t('active_admin.operator_documents_page.annexes') do |od|
      links = []
      od.operator_document_annexes.each { |a| links << link_to(a.id, admin_operator_document_annex_path(a)) }
      links.join(' ').html_safe
    end
    # rubocop:enable Rails/OutputSafety
    column :reason
    column :note
    column :response_date
    actions
  end

  filter :public
  filter :id
  filter :required_operator_document_country_id,
         label: I18n.t('activerecord.models.country.one'),
         as: :select,
         collection: -> { Country.by_name_asc.where(id: RequiredOperatorDocument.select(:country_id).distinct.pluck(:country_id)) }
  filter :operator_document_id_eq, label: I18n.t('active_admin.operator_documents_page.operator_document_id')
  filter :required_operator_document_contract_signature_eq,
         label: I18n.t('activerecord.attributes.required_operator_document.contract_signature'),
         as: :select, collection: [[I18n.t('active_admin.status_tag.yes'), true], [I18n.t('active_admin.status_tag.no'), false]]
  filter :operator_document_required_operator_document_id,
         label: I18n.t('activerecord.models.required_operator_document_group'),
         as: :select,
         collection: -> { RequiredOperatorDocument.with_translations.all }
  filter :operator,
         label: I18n.t('activerecord.models.operator'),
         as: :select,
         collection: -> { Operator.order(:name) }
  filter :fmu, label: I18n.t('activerecord.models.fmu.other'), as: :select, collection: -> { Fmu.with_translations(I18n.locale).order('fmu_translations.name') }
  filter :status, as: :select, collection: OperatorDocument.statuses
  filter :type, as: :select
  filter :source, as: :select, collection: OperatorDocument.sources
  filter :operator_document_updated_at

  controller do
    def scoped_collection
      end_of_association_chain.includes(
        :required_operator_document
      )
    end
  end
end
