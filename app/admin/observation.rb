# frozen_string_literal: true

ActiveAdmin.register Observation do
  extend BackRedirectable
  back_redirect

  menu false

  config.order_clause

  scope_to do
    Class.new do
      def self.observations
        Observation.unscoped
      end
    end
  end

  controller do
    def scoped_collection
      end_of_association_chain.includes([:translations, [country: :translations],
                                         :severity, [operator: :translations],
                                         [government: :translations],
                                         [subcategory: :translations], [observer_observations: [observer: :translations]],
                                         [fmu: :translations], :user, :observation_report])
    end
  end

  actions :all, except: [:new, :create]
  permit_params :name, :lng, :pv, :lat, :lon, :subcategory_id, :severity_id, :operator_id,
                :validation_status, :publication_date, :is_active, :observation_report_id,
                :location_information, :law_id, :fmu_id, observer_ids: [], relevant_operators: [],
                                  observation_documents_attributes: [:id, :name, :attachment],
                                  translations_attributes: [:id, :locale, :details, :evidence, :concern_opinion, :litigation_status, :_destroy]


  member_action :approve, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Approved'])
    redirect_to collection_path, notice: 'Observation approved'
  end

  member_action :reject, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Rejected'])
    redirect_to collection_path, notice: 'Observation rejected'
  end

  member_action :start_review, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Under revision'])
    redirect_to collection_path, notice: 'Observation under revision'
  end


  action_item :approve, only: :show do
    if ['Created', 'Under revision'].include? resource.validation_status
      link_to 'Approve', approve_admin_observation_path(observation),
              method: :put, data: { confirm: 'Do you want to APPROVE this observation?' }, notice: 'Observation Approved'
    end
  end

  action_item :reject, only: :show do
    if ['Created', 'Under revision'].include? resource.validation_status
      link_to 'Reject', reject_admin_observation_path(observation),
              method: :put, data: { confirm: 'Do you want to REJECT this observation?' }, notice: 'Observation Rejected'
    end
  end

  action_item :start_review, only: :show do
    if %w(Created Rejected Approved).include? resource.validation_status
      link_to 'Start Revision', start_review_admin_observation_path(observation),
              method: :put, notice: 'Observation Under Revision'
    end
  end

  batch_action :approve, confirm: 'Are you sure you want to approve all this observations?' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update_attributes(validation_status: Observation.validation_statuses['Approved'])
    end
    redirect_to collection_path, notice: 'Documents approved!'
  end

  batch_action :reject, confirm: 'Are you sure you want to reject all this observations?' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update_attributes(validation_status: Observation.validation_statuses['Rejected'])
    end
    redirect_to collection_path, notice: 'Documents rejected!'
  end

  batch_action :under_revision, confirm: 'Are you sure you want to put all this observations under revision?' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update_attributes(validation_status: Observation.validation_statuses['Under revision'])
    end
    redirect_to collection_path, notice: 'Documents put under revision!'
  end

  sidebar 'Documents', only: :show do
    attributes_table_for resource do
      ul do
        resource.observation_documents.collect do |od|
        li link_to(od.name, admin_evidence_path(od.id))
      end
      end
    end
  end

  scope :all, default: true
  scope :operator
  scope :government
  scope :pending
  scope :created

  filter :validation_status, as: :select, collection:
      Observation.validation_statuses.sort
  filter :country, as: :select,
          collection: -> { Country.joins(:observations).with_translations(I18n.locale).order('country_translations.name') }
  filter :observers, label: 'Observers', as: :select,
         collection: -> { Observer.with_translations(I18n.locale).order('observer_translations.name')}
  filter :operator, label: 'Operator', as: :select,
           collection: -> { Operator.with_translations(I18n.locale).order('operator_translations.name')}
  filter :government_translations_government_entity_contains,
         as: :select, label: 'Government Entity',
         collection: Government.with_translations(I18n.locale)
                         .order('government_translations.government_entity')
                         .pluck(:government_entity)
  filter :subcategory,
         label: 'Subcategory', as: :select,
         collection: -> { Subcategory.with_translations(I18n.locale).order('subcategory_translations.name')}
  filter :severity_level, as: :select, collection: [['Unknown', 0],['Low', 1], ['Medium', 2], ['High', 3]]
  filter :observation_report,
         label: 'Report', as: :select,
         collection: ObservationReport.order(:title)
  filter :user, label: 'User who created', as: :select, collection: User.order(:name)
  filter :modified_user, label: 'User who modified', as: :select, collection: User.order(:name)
  filter :is_active
  filter :publication_date
  filter :updated_at



  csv do
    column :id
    column :is_active
    column 'Status' do |observation|
      observation.validation_status
    end
    column :country do |observation|
      observation.country.name #if observation.country
    end
    column :fmu do |observation|
      observation.fmu&.name #if observation.fmu
    end
    column :location_information
    column :observers do |observation|
      observation.observers.map(&:name).join(', ')
    end
    column :operator do |observation|
      observation.operator&.name # if observation.operator
    end
    column :government do |observation|
      observation.government&.government_entity #if observation.government
    end
    column :relevant_operators do |observation|
      observation.relevant_operators.map(&:name).join(', ')
    end
    column :subcategory do |observation|
      observation.subcategory&.name
    end
    column :law do |observation|
      observation.law_id
    end
    column :severity do |observation|
      observation.severity&.level
    end
    column :publication_date
    column :actions_taken
    column :details
    column :evidence
    column :concern_opinion
    column :report do |observation|
      observation.observation_report&.title
    end
    column :user do |observation|
      observation.user&.name
    end
    column :modified_user do |observation|
      observation.modified_user&.name
    end
    column :created_at
    column :updated_at
  end


  index do
    selectable_column
    column :id
    column 'Active?', :is_active
    tag_column 'Status', :validation_status, sortable: 'validation_status'
    column :country, sortable: 'country_translations.name'
    column :fmu, sortable: 'fmu_translations.name'
    column :location_information, sortable: true
    column :observers, sortable: 'observer_translations.name' do |o|
      links = []
      o.observers.with_translations(I18n.locale).each do |observer|
        links << link_to(observer.name, admin_monitor_path(observer.id))
      end
      links.reduce(:+)
    end
    column :observation_type, sortable: 'observation_type'
    column :operator, sortable: 'operator_translations.name'
    column :government, sortable: 'government_translations.government_entity' do |o|
      o.government.government_entity if o.government.present?
    end
    column :relevant_operators do |o|
      links = []
      o.relevant_operators.each do |operator|
        links << link_to(operator.name, admin_producer_path(operator.id))
      end
      links.reduce(:+)
    end
    column :subcategory, sortable: 'subcategory_translations.name'

    column :law
    column(:law_country, sortable: 'country_translations.name') { |o| o.law&.country }
    column(:subcategory, sortable: 'subcategory_translations.name') { |o| o.law&.subcategory }
    column('Illegality as written by law', sortable: true) { |o| o.law&.written_infraction }
    column('Legal reference: Illegality', sortable: true) { |o| o.law&.infraction }
    column('Legal reference: Penalties', sortable: true) { |o| o.law&.sanctions }
    column('Minimum fine', sortable: true) { |o| o.law&.min_fine }
    column('Maximum fine', sortable: true) { |o| o.law&.max_fine }
    column(:currency) { |o| o.law&.currency }
    column(:penal_servitude, sortable: true) { |o| o.law&.penal_servitude }
    column(:other_penalties, sortable: true) { |o| o.law&.other_penalties }
    column('Indicator APV', sortable: true) { |o| o.law&.apv }

    column :severity, sortable: 'severities.level' do |o|
      o&.severity&.level
    end
    column :publication_date, sortable: true
    column :actions_taken
    column :details
    column :evidence
    column :concern_opinion
    column :pv
    column :lat
    column :lng
    column :is_physical_place
    column :litigation_status
    column :report, sortable: 'observation_reports.title' do |o|
      link_to o.observation_report.title, admin_observation_report_path(o.observation_report_id) if o.observation_report.present?
    end
    column :user, sortable: 'users.name'
    column :modified_user
    column :created_at
    column :updated_at
    column('Actions') do |observation|
      a 'Approve', href: approve_admin_observation_path(observation),      'data-method': :put if ['Ready for revision', 'Under revision', 'Rejected'].include?(observation.validation_status)
      a 'Reject',  href: reject_admin_observation_path(observation),       'data-method': :put if ['Ready for revision', 'Under revision', 'Approved'].include?(observation.validation_status)
      a 'Review',  href: start_review_admin_observation_path(observation), 'data-method': :put if ['Ready for revision', 'Approved', 'Rejected'].include?(observation.validation_status)
    end
    actions
  end

  form do |f|
    operator   = object.operator_id.present? ? true : false
    law        = object.law_id.present? ? true : false
    fmu        = object.fmu_id.present? ? true : false
    government = object.government_id.present? ? true : false

    f.semantic_errors *f.object.errors.keys
    f.inputs 'Status' do
      f.input :is_active
      f.input :validation_status
    end
    f.inputs 'Observation Details' do
      f.input :country, input_html: { disabled: true }
      f.input :observation_type, input_html: { disabled: true }
      f.input :subcategory, input_html: { disabled: true }
      f.input :law, input_html: { disabled: law },
                    collection: object.subcategory.laws.map {|l| [l.written_infraction, l.id]}
      f.input :severity, as: :select,
                         collection: object.subcategory.severities.map {|s| ["#{s.level} - #{s.details.first(80)}", s.id]}
      f.input :is_physical_place, input_html: { disabled: true }
      f.input :location_information  if f.object.observation_type == 'operator'
      f.input :fmu, input_html: { disabled: fmu } if f.object.observation_type == 'operator'
      f.input :observers
      if f.object.observation_type == 'government'
        f.input :government, as: :select,
                             collection: Government.all.map {|g| [g.government_entity, g.id] },
                             input_html: { disabled: government }
      end
      f.input :operator, input_html: { disabled: operator } if f.object.observation_type == 'operator'
      f.input :publication_date, as: :date_time_picker, picker_options: { timepicker: false }
      f.input :pv
      f.input :lat
      f.input :lng
      f.input :observation_report, as: :select
      f.has_many :observation_documents, new_record: 'Add evidence', heading: 'Evidence' do |t|
        t.input :name
        t.input :attachment
      end
    end
    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :details
        t.input :evidence
        t.input :concern_opinion
        t.input :litigation_status
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :is_active
      tag_row :validation_status
      row :country
      row :observation_type
      row :subcategory
      row :law
      row :severity do |o|
        o.severity.details
      end
      row :is_physical_place
      if resource.location_information.present?
        row :location_information
      end
      if resource.fmu.present?
        row :fmu
      end
      if resource.operator.present?
        row :operator
      end
      if resource.government.present?
        row :government do |o|
          o.government.government_entity
          o.relevant_operators
        end
      end
      row :publication_date
      row :pv
      row :lat
      row :lng
      row :actions_taken
      row :observation_report
      row :user
      row :modified_user
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

end
