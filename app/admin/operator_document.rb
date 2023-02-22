# frozen_string_literal: true

ActiveAdmin.register OperatorDocument do
  extend BackRedirectable
  extend Versionable

  menu false
  config.sort_order = 'updated_at_desc'

  active_admin_paranoia

  scope_to do
    Class.new do
      def self.operator_documents
        OperatorDocument.unscoped
      end
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain
        .includes([:required_operator_document, :user, :operator,
                   [fmu: :translations],
                   [required_operator_document:
                      [required_operator_document_group: :translations, country: :translations]]])
    end
  end

  # Here we're updating the documents one by one to make sure the callbacks to
  # create a new version and to change the last modified (and the author) are called
  batch_action :make_private, confirm: I18n.t('active_admin.operator_documents_page.confirm_private') do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(public: false)
    end
    redirect_to collection_path, notice: I18n.t('active_admin.operator_documents_page.private_confirmed')
  end

  batch_action :make_public, confirm: I18n.t('active_admin.operator_documents_page.confirm_public') do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(public: true)
    end
    redirect_to collection_path, notice: I18n.t('active_admin.operator_documents_page.public_confirmed')
  end

  batch_action :set_source_by_company,
               confirm: I18n.t('active_admin.operator_documents_page.confirm_company') do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(source: OperatorDocument.sources[:company])
    end
    redirect_to collection_path, notice: I18n.t('active_admin.operator_documents_page.company_confirmed')
  end

  batch_action :set_source_by_forest_atlas,
               confirm: I18n.t('active_admin.operator_documents_page.confirm_fa') do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(source: OperatorDocument.sources[:forest_atlas])
    end
    redirect_to collection_path, notice: I18n.t('active_admin.operator_documents_page.fa_confirmed')
  end

  batch_action :set_source_by_other,
               confirm: I18n.t('active_admin.operator_documents_page.confirm_other') do |ids|
    batch_action_collection.find(ids).each do |doc|
      doc.update(source: OperatorDocument.sources[:other_source])
    end
    redirect_to collection_path, notice: I18n.t('active_admin.operator_documents_page.other_confirmed')
  end

  member_action :approve, method: :put do
    if resource.reason.present?
      resource.update(status: OperatorDocument.statuses[:doc_not_required])
    else
      resource.update(status: OperatorDocument.statuses[:doc_valid])
    end
    redirect_to collection_path, notice: I18n.t('active_admin.operator_documents_page.approved')
  end

  member_action :reject, method: :put do
    resource.update(status: OperatorDocument.statuses[:doc_invalid], reason: nil)

    redirect_to collection_path, notice: I18n.t('active_admin.operator_documents_page.rejected')
  end

  sidebar I18n.t('active_admin.operator_documents_page.annexes'), only: :show do
    attributes_table_for resource do
      ul do
        resource.operator_document_annexes.collect do |annex|
          li link_to(annex.name, admin_operator_document_annex_path(annex.id))
        end
      end
    end
  end

  actions :all, except: [:destroy, :new]
  permit_params :name, :public, :required_operator_document_id,
                :operator_id, :type, :status, :expire_date, :start_date,
                :uploaded_by, :reason, :note, :response_date,
                :source, :source_info, document_file_attributes: [:id, :attachment, :filename]

  csv do
    column :exists do |o|
      o.deleted_at.nil? && o.required_operator_document.deleted_at.nil?
    end
    column :public
    column :status
    column :id
    column :required_operator_document do |o|
      o.required_operator_document.name
    end
    column :country do |o|
      o.required_operator_document&.country&.name
    end
    column :Type do |o|
      if o.required_operator_document.present?
        o.required_operator_document.type == 'RequiredOperatorDocumentFmu' ? 'Fmu' : 'Operator'
      else
        RequiredOperatorDocument.unscoped.find(o.required_operator_document_id).type
      end
    end
    column :operator do |o|
      o.operator.name
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
    column :created_at
    column :uploaded_by
    column :attachment do |o|
      o&.document_file&.attachment
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
    render partial: 'hidden_filters', locals: {
        filter: {
            countries: {
                operators: HashHelper.aggregate(Operator.pluck(:country_id, :id).map{ |x| { x.first => x.last } }),
                required_operator_documents:
                  HashHelper.aggregate(RequiredOperatorDocument.pluck(:country_id, :id).map{ |x| { x.first => x.last } })
            }
        }
    }
    selectable_column
    bool_column I18n.t('active_admin.required_operator_document_page.exists') do |od|
      od.deleted_at.nil? && od.required_operator_document.deleted_at.nil?
    end
    column :public
    tag_column :status
    column :id
    column :country do |od|
      od.required_operator_document.country
    end
    column I18n.t('active_admin.operator_documents_page.required'), :required_operator_document, sortable: 'required_operator_document_id' do |od|
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
    column :operator, sortable: 'operator_id'
    column :fmu, sortable: 'fmu_id' do |od|
      if od.fmu.present?
        link_to od.fmu.name, admin_fmu_path(od.fmu)
      elsif od.fmu_id.present?
        Fmu.unscoped.find(od.fmu_id).name
      end
    end
    column I18n.t('active_admin.operator_documents_page.legal_category') do |od|
      if od.required_operator_document.present?
        od.required_operator_document.required_operator_document_group.name
      else
        RequiredOperatorDocument.unscoped.find(od.required_operator_document_id).required_operator_document_group.name
      end
    end
    column :user, sortable: 'user_id'
    column :expire_date
    column :start_date
    column :deleted_at
    column :created_at
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
    column(I18n.t('active_admin.approve')) { |observation| link_to I18n.t('active_admin.approve'), approve_admin_operator_document_path(observation), method: :put }
    column(I18n.t('active_admin.reject')) { |observation| link_to I18n.t('active_admin.reject'), reject_admin_operator_document_path(observation), method: :put }
    actions
  end

  filter :public
  filter :id
  filter :required_operator_document_country_id,
         label: I18n.t('activerecord.models.country.one'),
         as: :select,
         collection: -> { Country.with_translations(I18n.locale).order('country_translations.name') }
  filter :required_operator_document,
         collection: -> {
           rod_table = RequiredOperatorDocument.arel_table
           country_t_table = Country::Translation.arel_table
           country_name = Arel::Nodes::NamedFunction.new('coalesce', [country_t_table[:name], Arel::Nodes::SqlLiteral.new("'Generic'")]).as('country_name')

           query =
             RequiredOperatorDocument
               .select(rod_table[:name], country_name, rod_table[:id])
               .left_joins(country: :translations)
               .arel
               .on("country_translations.country_id = countries.id and country_translations.locale = '#{I18n.locale}'")
               .order('required_operator_documents.name')
           RequiredOperatorDocument.find_by_sql(query.to_sql).map { ["#{_1[:name]} - #{_1[:country_name]}", _1[:id]] }
         }
  filter :operator, as: :select,
                    collection: -> { Operator.order(:name) }
  filter :fmu, label: I18n.t('activerecord.models.fmu.other'), as: :select,
               collection: -> { Fmu.with_translations(I18n.locale).order('fmu_translations.name') }
  filter :status, as: :select, collection: -> { OperatorDocument.statuses }
  filter :type, as: :select
  filter :source, as: :select, collection: -> { OperatorDocument.sources }
  filter :updated_at

  scope I18n.t('active_admin.operator_documents_page.pending'), :doc_pending

  form do |f|
    f.semantic_errors *f.object.errors.attribute_names
    f.inputs I18n.t('active_admin.operator_documents_page.details') do
      f.input :required_operator_document, input_html: { disabled: true }
      f.input :operator, input_html: { disabled: true }
      f.input :type, input_html: { disabled: true }
      f.input :uploaded_by, default: OperatorDocument.uploaded_bies[:admin]
      f.input :source
      f.input :source_info
      f.input :status, include_blank: false
      f.input :public
      f.inputs for: [:document_file_attributes, f.object.document_file || DocumentFile.new] do |df|
        df.input :attachment
      end
      f.input :reason
      f.input :note
      f.input :response_date, as: :date_picker
      f.input :expire_date, as: :date_picker
      f.input :start_date, as: :date_picker
    end
    f.actions
  end

  show title: proc{ "#{resource.operator.name} - #{resource.required_operator_document.name}" } do
    attributes_table do
      row :public
      tag_row :status
      row :required_operator_document
      row :operator
      row :fmu, unless: resource.is_a?(OperatorDocumentCountry)
      row :uploaded_by
      row I18n.t('active_admin.operator_documents_page.attachment') do |r|
        link_to r.document_file&.attachment&.identifier, r.document_file&.attachment&.url
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
