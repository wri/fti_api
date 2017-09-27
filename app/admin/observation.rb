ActiveAdmin.register Observation do
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
                :law_id, observer_ids: [],
                observation_documents_attributes: [:id, :name, :attachment],
                translations_attributes: [:id, :locale, :details, :evidence, :concern_opinion, :litigation_status]


  member_action :approve, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Approved'])
    redirect_to collection_path, notice: 'Document approved'
  end

  member_action :reject, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Rejected'])
    redirect_to collection_path, notice: 'Document rejected'
  end

  member_action :start_review, method: :put do
    resource.update_attributes(validation_status: Observation.validation_statuses['Under revision'])
    redirect_to collection_path, notice: 'Document under revision'
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
      observation.update_attributes(validation_status: Observation.validation_statuses['Under Revision'])
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

  filter :validation_status, as: :select, collection: Observation.validation_statuses
  filter :country
  filter :observers
  filter :operator
  filter :government_translations_government_entity_contains, as: :select, label: 'Government Entity',
         collection: Government.joins(:translations).pluck(:government_entity)
  filter :subcategory
  filter :severity_level, as: :select, collection: [['Unknown', 0],['Low', 1], ['Medium', 2], ['High', 3]]
  filter :observation_report
  filter :user
  filter :modified_user
  filter :is_active
  filter :publication_date
  filter :updated_at

  index do
    selectable_column
    column :id
    column 'Active?', :is_active
    tag_column 'Status', :validation_status, sortable: true
    column :country, sortable: 'country_translations.name'
    column :fmu, sortable: 'fmu_translations.name'
    column :observers, sortable: 'observer_translations.name' do |o|
      o.observers.pluck(:name).join(', ')
    end
    column :operator, sortable: 'operator_translations.name'
    column :government, sortable: 'government_translations.government_entity' do |o|
      o.government.government_entity if o.government.present?
    end
    column :subcategory, sortable: 'subcategory_translations.name'
    column :law
    column :severity, sortable: 'severities.level' do |o|
      o.severity.level
    end
    column :publication_date, sortable: true
    column :actions_taken
    column :details
    column :evidence
    column :concern_opinion
    column :report, sortable: 'observation_reports.title' do |o|
      link_to o.observation_report.title, admin_observation_report_path(o.observation_report_id) if o.observation_report.present?
    end
    column :user, sortable: 'users.name'
    column :modified_user
    column :created_at
    column :updated_at
    column('Actions') do |observation|
      a 'Approve', href: approve_admin_observation_path(observation),      'data-method': :put
      a 'Reject',  href: reject_admin_observation_path(observation),       'data-method': :put
      a 'Review',  href: start_review_admin_observation_path(observation), 'data-method': :put
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
      f.input :fmu, input_html: { disabled: fmu } if f.object.observation_type == 'operator'
      f.input :observers
      f.input :government, as: :select,
              collection: Government.all.map {|g| [g.government_entity, g.id] },
              input_html: { disabled: government } if f.object.observation_type == 'government'
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
end