# frozen_string_literal: true

ActiveAdmin.register Operator, as: 'Producer' do
  extend BackRedirectable
  extend Versionable

  menu false

  config.order_clause

  actions :all
  permit_params :holding_id, :name, :fa_id, :operator_type, :country_id, :details, :concession, :is_active,
                :logo, :delete_logo, :email, fmu_ids: []

  member_action :activate, method: :put do
    resource.update(is_active: true)
    redirect_back fallback_location: admin_producers_path, notice: I18n.t('active_admin.operator_page.producer_activated')
  end

  member_action :deactivate, method: :put do
    resource.update(is_active: false)
    redirect_back fallback_location: admin_producers_path, notice: I18n.t('active_admin.operator_page.producer_deactivated')
  end

  config.clear_action_items!

  action_item :toggle_active, only: [:show] do
    if resource.is_active
      link_to I18n.t('shared.deactivate'), deactivate_admin_producer_path(resource),
              method: :put, data: { confirm:  I18n.t('active_admin.operator_page.confirm_deactivate', name: resource.name)  }
    else
      link_to I18n.t('shared.activate'), activate_admin_producer_path(resource),
              method: :put, data: { confirm: I18n.t('active_admin.operator_page.confirm_activate', name: resource.name) }
    end
  end

  action_item :edit, only: [:show] do
    link_to I18n.t('active_admin.operator_page.edit'), edit_admin_producer_path(resource)
  end

  action_item :delete, only: [:show], if: -> { resource.can_hard_delete? } do
    link_to I18n.t('active_admin.operator_page.delete'),
            admin_producer_path(resource),
            method: :delete,
            data: { confirm: I18n.t('active_admin.operator_page.confirm_delete') }
  end

  action_item :new, only: [:index] do
    link_to I18n.t('active_admin.operator_page.new'), new_admin_producer_path
  end

  csv do
    column :id
    column :holding_id
    column :is_active
    column :country do |operator|
      operator.country.name rescue nil
    end
    column :fa_id
    column :name
    column :details
    column :email
    column :concession
    column :score_absolute do |operator|
      "#{'%.2f' % operator.score_operator_observation&.score}" rescue nil
    end
    column :obs_per_visit do |operator|
      operator.score_operator_observation&.obs_per_visit
    end
    column I18n.t('active_admin.operator_page.docs_perc') do |operator|
      operator.score_operator_document&.all
    end
  end

  index title: I18n.t('active_admin.operator_page.producer') do
    column :is_active
    column :id
    column :holding
    column :country, sortable: 'country_translations.name'
    column :name, sortable: :name
    column :fmu do |operator|
      fmus = []
      operator.fmus.each do |fmu|
        fmus << (link_to fmu.name, admin_fmu_path(fmu))
      end
      fmus.reduce(:+)
    end
    column I18n.t('active_admin.operator_page.obs_visit'), :obs_per_visit, sortable: true do |operator|
      operator.score_operator_observation&.obs_per_visit
    end
    column I18n.t('active_admin.operator_page.docs_perc'), :percentage_valid_documents_all, sortable: true do |operator|
      (operator.score_operator_document.all * 100).to_i rescue nil
    end
    column(I18n.t('active_admin.shared.actions')) do |operator|
      if operator.is_active
        link_to I18n.t('shared.deactivate'), deactivate_admin_producer_path(operator),
                method: :put, data: { confirm: I18n.t('active_admin.operator_page.confirm_deactivate', name: operator.name) }
      else
        link_to I18n.t('shared.activate'), activate_admin_producer_path(operator),
                method: :put, data: { confirm: I18n.t('active_admin.operator_page.confirm_activate', name: operator.name) }
      end
    end

    actions defaults: false do |operator|
      item I18n.t('active_admin.view'), admin_producer_path(operator)
      item I18n.t('active_admin.edit'), edit_admin_producer_path(operator)
      if operator.can_hard_delete?
        item I18n.t('active_admin.delete'), admin_producer_path(operator), method: :delete, data: { confirm: I18n.t('active_admin.operator_page.confirm_delete') }
      end
    end
  end

  scope I18n.t('active_admin.all'), :all, default: true
  scope I18n.t('active_admin.shared.active'), :active
  scope I18n.t('active_admin.shared.inactive'), :inactive

  filter :country,
         as: :select,
         collection: -> { Country.joins(:operators).with_translations(I18n.locale).order('country_translations.name') }
  filter :name_eq,
         as: :select, label: I18n.t('activerecord.attributes.operator.name'),
         collection: -> { Operator.order(:name).pluck(:name) }
  filter :concession, as: :select
  filter :fa_id_present, as: :boolean, label: I18n.t('active_admin.operator_page.with_fa_uuid')
  filter :fmus_id_null, as: :boolean, label: I18n.t('active_admin.operator_page.fmus_id_null')

  dependent_filters do
    {
      country_id: {
        name_eq: Operator.pluck(:country_id, :name)
      }
    }
  end

  sidebar I18n.t('activerecord.models.fmu.other'), only: :show do
    attributes_table_for resource do
      ul do
        resource.fmus.collect do |fmu|
          li link_to(fmu.name, admin_fmu_path(fmu.id))
        end
      end
    end
  end

  sidebar I18n.t('activerecord.models.observation.other'), only: :show do
    attributes_table_for resource do
      # rubocop:disable Rails/OutputSafety
      div do
        resource.all_observations.order(:id).collect do |observation|
          link_to(observation.id, admin_observation_path(observation.id))
        end.join(', ').html_safe
      end
      # rubocop:enable Rails/OutputSafety
    end
  end

  sidebar I18n.t('activerecord.models.sawmill'), only: :show do
    attributes_table_for resource do
      ul do
        resource.sawmills.collect do |sawmill|
          li link_to(sawmill.name, admin_sawmill_path(sawmill.id))
        end
      end
    end
  end

  sidebar I18n.t('active_admin.operator_page.valid_documents'), only: :show, if: proc{ resource.operator_documents.where(status: 'doc_valid').any? } do
    table_for resource.operator_documents.where(status: 'doc_valid').collect do |od|
      column('') { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
    end
  end

  sidebar I18n.t('active_admin.operator_page.pending_documents'), only: :show, if: proc{ resource.operator_documents.where(status: 'doc_pending').any? } do
    table_for resource.operator_documents.where(status: 'doc_pending').collect do |od|
      column('') { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
    end
  end

  sidebar I18n.t('active_admin.operator_page.invalid_documents'), only: :show,
                                                                  if: proc{ resource.operator_documents.where(status: %w(doc_not_provided doc_invalid doc_expired)).any? } do
    table_for resource.operator_documents.where(status: %w(doc_not_provided doc_invalid doc_expired)).collect do |od|
      column('') { |od| link_to od.required_operator_document.name, admin_operator_document_path(od.id) }
    end
  end


  form do |f|
    edit = f.object.new_record? ? false : true
    f.semantic_errors *f.object.errors.attribute_names
    f.inputs I18n.t('active_admin.operator_page.operator_details') do
      f.input :name
      f.input :details
      f.input :holding, as: :select
      f.input :email
      f.input :fa_id, as: :string, label: I18n.t('active_admin.operator_page.with_fa_uuid')
      f.input :operator_type, as: :select,
                              collection: ['Logging company', 'Artisanal', 'Community forest', 'Estate',
                                           'Industrial agriculture', 'Mining company',
                                           'Sawmill', 'Other', 'Unknown']
      f.input :country, input_html: { disabled: edit }
      f.input :concession

      if f.object.logo.present?
        f.input :logo, as: :file, hint: image_tag(f.object.logo.url(:thumbnail))
        f.input :delete_logo, as: :boolean, required: false, label: I18n.t('active_admin.operator_page.remove_logo')
      else
        f.input :logo, as: :file
      end
      available_fmus = Fmu.filter_by_free
      if edit
        available_fmus = []
        Fmu.filter_by_free.find_each{ |x| available_fmus << x }
        f.object.fmus.find_each{ |x| available_fmus << x }
        f.input :fmus, collection: available_fmus, input_html: { disabled: true }
      else
        f.input :fmus, collection: available_fmus
      end
      f.input :is_active
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :is_active
      row :holding
      row :name
      row :email
      row :operator_type
      row :fa_id
      row :details
      row :country
      row :concession
      row :logo do |o|
        link_to o.logo&.identifier, o.logo&.url if o.logo&.url
      end
      row :address
      row :website
      row :fmus
      row :percentage_valid_documents_all do |operator|
        operator.score_operator_document&.all
      end
      row :obs_per_visit do |operator|
        operator.score_operator_observation&.obs_per_visit
      end
      row :score_absolute do |operator|
        operator.score_operator_observation&.score
      end
      row :created_at
      row :updated_at
      if resource.fa_id.present?
        grouped_sod = ScoreOperatorDocument.where(operator_id: resource.id).group_by_day(:date, series: false)
        row :total_documents do
          render partial: 'score_evolution', locals: {
            scores: grouped_sod.maximum(:total)
          }
        end
        row :percentage_by_type do
          render partial: 'score_evolution', locals: {
            scores: [
              { name: 'all', data: grouped_sod.maximum(:all) },
              { name: 'per_country', data: grouped_sod.maximum(:country) },
              { name: 'per_fmus', data: grouped_sod.maximum(:fmu) }
            ]
          }
        end

        row I18n.t('active_admin.operator_page.score_history_table') do
          scores = ScoreOperatorDocument.where(operator_id: resource.id).order(date: :desc).to_a
          table_for ScoreOperatorDocumentDecorator.decorate_collection(scores, self) do
            column :date
            column :all
            column :fmu
            column :country
            column :total
            column :public_summary_diff do |score|
              idx = scores.index(score.model)
              prev_score = scores[idx + 1]
              score.public_summary_diff(prev_score)
            end
            column :private_summary_diff do |score|
              idx = scores.index(score.model)
              prev_score = scores[idx + 1]
              score.private_summary_diff(prev_score)
            end
            column I18n.t('active_admin.operator_page.documents'), &:document_history_link
          end
        end
      end
    end
    active_admin_comments
  end

  controller do
    def find_resource
      scoped_collection.unscope(:joins).where(id: params[:id]).first!
    end

    def scoped_collection
      end_of_association_chain
        .includes(
          :score_operator_document,
          :score_operator_observation,
          country: :translations,
        )
    end
  end
end
