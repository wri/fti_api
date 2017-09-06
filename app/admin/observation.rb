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
                                         [subcategory: :translations], [observer_observations: [observer: :translations]],
                                         [fmu: :translations], :user, :observation_report])
    end
  end

  actions :all, except: [:new, :create]
  permit_params :name, :lng, :pv, :lat, :lon, :subcategory_id, :severity_id,
                :validation_status, :publication_date, :is_active, :observer_ids,
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

  scope :all, default: true
  scope :operator
  scope :government

  index do
    selectable_column
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
      o.observation_report.title if o.observation_report.present?
    end
    column :user, sortable: 'users.name'
    column :modified_user
    column :created_at
    column :updated_at
    column('Approve') { |observation| link_to 'Approve', approve_admin_observation_path(observation), method: :put}
    column('Reject') { |observation| link_to 'Reject', reject_admin_observation_path(observation), method: :put}
    column('Review') { |observation| link_to 'Review', start_review_admin_observation_path(observation), method: :put}
    actions
  end

  filter :validation_status, as: :check_boxes, collection: Observation.validation_statuses
  filter :country
  filter :operator
  filter :observers
  filter :subcategory
  filter :severity_level, as: :check_boxes, collection: [['Unknown', 0],['Low', 1], ['Medium', 2], ['High', 3]]
  filter :is_active
  filter :publication_date
  filter :updated_at


  form do |f|
    f.semantic_errors *f.object.errors.keys
    f.inputs 'Country Details' do
      f.input :country, input_html: { disabled: true }
      f.input :observation_type, input_html: { disabled: true }
      f.input :subcategory, input_html: { disabled: true }
      f.input :law, input_html: { disabled: true }
      f.input :severity, as: :select,
              collection: Severity.all.map {|s| ["#{s.level} - #{s.details.first(80)}", s.id]}
      f.input :fmu, input_html: { disabled: true }
      f.input :observers
      f.input :government, as: :select,
              collection: Government.all.map {|g| [g.government_entity, g.id] },
              input_html: { disabled: true } if f.object.observation_type == 'government'
      f.input :operator, input_html: { disabled: true } if f.object.observation_type == 'operator'
      f.input :publication_date, as: :date_picker
      f.input :pv
      f.input :lat
      f.input :lng
      #f.input :law
      f.input :observation_report, as: :select
      #f.input :observation_documents
      f.input :validation_status
      f.input :is_active
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