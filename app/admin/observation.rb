# frozen_string_literal: true

ActiveAdmin.register Observation do
  extend BackRedirectable
  back_redirect

  extend Versionable
  versionate

  active_admin_paranoia

  menu false

  PER_PAGE = [10, 20, 40, 60].freeze

  config.order_clause
  config.per_page = PER_PAGE

  before_action only: :index do
    if PER_PAGE.include? params[:per_page]
      @per_page = params[:per_page]
      session[:obs_per_page] = @per_page
    else
      session[:obs_per_page] = PER_PAGE.include?(session[:obs_per_page]) ? session[:obs_per_page] : 10
      @per_page = session[:obs_per_page]
    end
  end

  scope_to do
    Class.new do
      def self.observations
        Observation.unscoped
      end
    end
  end

  actions :all, except: [:new]
  permit_params :name, :lng, :pv, :lat, :lon, :subcategory_id, :severity_id, :operator_id,
                :validation_status, :publication_date, :is_active, :observation_report_id,
                :location_information, :evidence_type, :evidence_on_report, :location_accuracy,
                :law_id, :fmu_id, :hidden, :admin_comment, :monitor_comment, :actions_taken,
                :responsible_admin_id, observer_ids: [], relevant_operator_ids: [], government_ids: [],
                                       observation_documents_attributes: [:id, :name, :attachment],
                                       translations_attributes: [:id, :locale, :details, :concern_opinion, :litigation_status, :_destroy]


  member_action :ready_for_publication, method: :put do
    resource.update(validation_status: Observation.validation_statuses['Ready for publication'])
    redirect_to collection_path, notice: 'Observation approved'
  end

  member_action :needs_revision, method: :put do
    resource.update(validation_status: Observation.validation_statuses['Needs revision'])
    redirect_to collection_path, notice: 'Observation needs revision'
  end

  member_action :start_qc, method: :put do
    resource.update(validation_status: Observation.validation_statuses['QC in progress'])
    redirect_to collection_path, notice: 'QC in progress for observations'
  end

  action_item :ready_for_publication, only: :show do
    if resource.validation_status == 'QC in progress'
      link_to 'Ready for publication', ready_for_publication_admin_observation_path(observation),
              method: :put, data: { confirm: 'Do you want to mark this observation as ready for publication?' },
              notice: 'Observation Approved'
    end
  end

  action_item :needs_revision, only: :show do
    if resource.validation_status == 'QC in progress'
      link_to 'Needs revision', needs_revision_admin_observation_path(observation),
              method: :put, data: { confirm: 'Do you want to notify the IM this needs revision?' },
              notice: 'Observation Needs revision'
    end
  end

  action_item :start_qc, only: :show do
    if resource.validation_status == 'Ready for QC'
      link_to 'Start QC', start_qc_admin_observation_path(observation),
              method: :put, notice: 'Observation in QC'
    end
  end

  batch_action :move_to_qc_in_progress, confirm: 'Are you sure you want to start QC for all these observations?' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update(validation_status: Observation.validation_statuses['QC in progress']) if observation.validation_status == 'Ready for QC'
    end
    redirect_to collection_path, notice: 'QC started'
  end

  batch_action :move_to_needs_revision, confirm: 'Are you sure you want to require revision for all these observations?' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update(validation_status: Observation.validation_statuses['Needs revision']) if observation.validation_status == 'QC in progress'
    end
    redirect_to collection_path, notice: 'Required revision for observations'
  end

  batch_action :move_to_ready_for_publication, confirm: 'Are you sure you want to mark these publications as ready to publish?' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update(validation_status: Observation.validation_statuses['Ready for publication']) if observation.validation_status == 'QC in progress'
    end
    redirect_to collection_path, notice: 'Observations ready to be published'
  end

  batch_action :move_to_published_no_comments, confirm: 'Are you sure you want to mark these publications as published without comments? No validation will be done!!' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update(validation_status: 'Published (no comments)')
    end
    redirect_to collection_path, notice: 'Observations published without comments'
  end

  batch_action :move_to_published_not_modified, confirm: 'Are you sure you want to mark these publications as published without modifications? No validation will be done!!' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update(validation_status: 'Published (not modified)')
    end
    redirect_to collection_path, notice: 'Observations published without modifications'
  end

  batch_action :move_to_published_modified, confirm: 'Are you sure you want to mark these publications as published with modifications? No validation will be done!!' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update(validation_status: 'Published (modified)')
    end
    redirect_to collection_path, notice: 'Observations published with modifications'
  end

  batch_action :hide, confirm: 'Are you sure you want to hide all the selected observations?' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update(hidden: true)
    end
    redirect_to collection_path, notice: 'Documents hidden!'
  end

  batch_action :unhide, confirm: 'Are you sure you want to un-hide all the selected observations?' do |ids|
    batch_action_collection.find(ids).each do |observation|
      observation.update(hidden: false)
    end
    redirect_to collection_path, notice: 'Documents un-hidden!'
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
  scope :published
  scope :created
  scope :hidden
  scope :visible

  filter :id, as: :numeric_range
  filter :validation_status,
         as: :select,
         input_html: { multiple: true },
         collection: -> { Observation.validation_statuses.sort }
  filter :country, as: :select,
                   collection: -> { Country.joins(:observations).with_translations(I18n.locale).order('country_translations.name') }
  filter :operator, label: 'Operator', as: :select,
                    collection: -> { Operator.with_translations(I18n.locale).order('operator_translations.name') }
  filter :fmu, as: :select, label: 'Fmus',
               collection: -> { Fmu.with_translations(I18n.locale).order('fmu_translations.name') }
  filter :governments, as: :select, label: 'Government Entity',
                       collection: -> {
                         Government.with_translations(I18n.locale)
                           .order('government_translations.government_entity')
                           .pluck('government_translations.government_entity', 'government_translations.government_id')
                       }
  filter :subcategory_category_id_eq,
         label: 'Category', as: :select,
         collection: -> { Category.with_translations(I18n.locale).order('category_translations.name') }
  filter :subcategory,
         label: 'Subcategory', as: :select,
         collection: -> { Subcategory.with_translations(I18n.locale).order('subcategory_translations.name') }
  filter :severity_level, as: :select, collection: [['Unknown', 0],['Low', 1], ['Medium', 2], ['High', 3]]
  filter :observers, label: 'Observers', as: :select,
                     collection: -> { Observer.with_translations(I18n.locale).order('observer_translations.name') }
  filter :observation_report,
         label: 'Report', as: :select,
         collection: -> { ObservationReport.order(:title) }
  filter :user, label: 'User who created', as: :select, collection: -> { User.order(:name) }
  filter :modified_user, label: 'User who modified', as: :select, collection: -> { User.order(:name) }
  filter :is_active
  filter :publication_date
  filter :updated_at
  filter :deleted_at


  csv do
    column :id
    column :is_active
    column :hidden
    column :observation_type
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
      observation.governments.map(&:government_entity)
    end
    column :relevant_operators do |observation|
      observation.relevant_operators.map(&:name).join(', ')
    end
    column :category do |observation|
      observation.subcategory&.category&.name
    end
    column :subcategory do |observation|
      observation.subcategory&.name
    end
    column :law do |observation|
      observation.law_id
    end
    column :written_infraction do |observation|
      observation.law&.written_infraction
    end
    column :infraction do |observation|
      observation.law&.infraction
    end
    column :sanctions do |observation|
      observation.law&.sanctions
    end
    column :min_fine do |observation|
      observation.law&.min_fine
    end
    column :max_fine do |observation|
      observation.law&.max_fine
    end
    column :currency do |observation|
      observation.law&.currency
    end
    column :penal_servitude do |observation|
      observation.law&.penal_servitude
    end
    column :other_penalties do |observation|
      observation.law&.other_penalties
    end
    column :indicator_apv do |observation|
      observation.law&.apv
    end
    column :severity do |observation|
      observation.severity&.level
    end
    column :publication_date
    column :actions_taken
    column :details
    column :evidence_type
    column :evidences do |observation|
      evidences = []
      observation.observation_documents.each do |d|
        evidences << d.name
      end
      evidences.join(' | ')
    end
    column :evidence_on_report
    column :concern_opinion
    column :pv
    column :location_accuracy
    column :lat
    column :lng
    column :is_physical_place
    column :litigation_status
    column :report do |observation|
      observation.observation_report&.title
    end
    column :admin_comment
    column :monitor_comment
    column :responsible_admin
    column :user do |observation|
      observation.user&.name
    end
    column :modified_user do |observation|
      observation.modified_user&.name
    end
    column :created_at
    column :updated_at
    column :deleted_at
  end


  index do
    render partial: 'hidden_filters', locals: {
        filter: {
            categories: {
                subcategories: HashHelper.aggregate(Subcategory.distinct.pluck(:category_id, :id).map{ |x| { x.first => x.last } })
            },
            countries: {
                government_entities: HashHelper.aggregate(Government.pluck(:country_id, :id).map{ |x| { x.first => x.last } }),
                operators: HashHelper.aggregate(Operator.pluck(:country_id, :id).map{ |x| { x.first => x.last } }),
                fmus: HashHelper.aggregate(Fmu.pluck(:country_id, :id).map{ |x| { x.first => x.last } })
            },
            operators: { fmus: HashHelper.aggregate(Fmu.joins(:operators).pluck('operators.id', :id).map{ |x| { x.first => x.last } }) }
        }
    }
    selectable_column
    column :id
    column 'Active?', :is_active
    column :hidden
    tag_column 'Status', :validation_status, sortable: 'validation_status'
    column :country, sortable: false
    column :fmu, sortable: false
    column :location_information, sortable: false
    column :observers, sortable: false do |o|
      links = []
      observers = params['scope'].eql?('recycle_bin') ? o.observers.unscope(where: :deleted_at) : o.observers
      observers.with_translations(I18n.locale).each do |observer|
        links << link_to(observer.name, admin_monitor_path(observer.id))
      end
      links.reduce(:+)
    end
    column :observation_type, sortable: 'observation_type'
    column :operator, sortable: false
    column :governments, sortable: false do |o|
      governments = params['scope'].eql?('recycle_bin') ? o.governments.unscope(where: :deleted_at) : o.governments
      governments.each_with_object([]) do |government, links|
        links << link_to(government.government_entity, admin_government_path(government.id))
      end.reduce(:+)
    end
    column :relevant_operators do |o|
      links = []
      relevant_operators = params['scope'].eql?('recycle_bin') ? o.relevant_operators.unscope(where: :deleted_at) : o.relevant_operators
      relevant_operators.each do |operator|
        links << link_to(operator.name, admin_producer_path(operator.id))
      end
      links.reduce(:+)
    end
    column :subcategory, sortable: false

    column('Illegality as written by law', sortable: false) { |o| o.law&.written_infraction }
    column('Legal reference: Illegality', sortable: false) { |o| o.law&.infraction }
    column('Legal reference: Penalties', sortable: false) { |o| o.law&.sanctions }
    column('Minimum fine', sortable: false) { |o| o.law&.min_fine }
    column('Maximum fine', sortable: false) { |o| o.law&.max_fine }
    column(:currency) { |o| o.law&.currency }
    column(:penal_servitude, sortable: false) { |o| o.law&.penal_servitude }
    column(:other_penalties, sortable: false) { |o| o.law&.other_penalties }
    column('Indicator APV', sortable: false) { |o| o.law&.apv }

    column :severity, sortable: false do |o|
      o&.severity&.level
    end
    column :publication_date, sortable: true
    column :actions_taken, sortable: false do |o|
      o.actions_taken[0..100] + (o.actions_taken.length >= 100 ? '...' : '') if o.actions_taken
    end
    column :details
    column :evidence_type
    column :evidences do |o|
      links = []
      o.observation_documents.each do |d|
        links << link_to(d.name, admin_evidences_path(d.id))
      end
      links.reduce(:+)
    end
    column 'Evidence in the report', :evidence_on_report, sortable: false
    column :concern_opinion do |o|
      o.concern_opinion[0..100] + (o.concern_opinion.length >= 100 ? '...' : '') if o.concern_opinion
    end
    column :pv, sortable: false
    column :location_accuracy, sortable: false
    column :lat, sortable: false
    column :lng, sortable: false
    column :is_physical_place, sortable: false
    column :litigation_status
    column :report, sortable: false do |o|
      title = o.observation_report.title[0..100] + (o.observation_report.title.length >= 100 ? '...' : '') if o.observation_report&.title
      link_to title, admin_observation_report_path(o.observation_report_id) if o.observation_report.present?
    end
    column :admin_comment, sortable: false
    column :monitor_comment, sortable: false
    column :responsible_admin
    column :user, sortable: false
    column :modified_user, sortable: false
    column :modified_user_language, sortable: false do |o|
      o.modified_user&.locale
    end
    column :created_at
    column :updated_at
    column :deleted_at
    column('Actions') do |observation|
      a 'Start QC', href: start_qc_admin_observation_path(observation),    'data-method': :put if observation.validation_status == 'Ready for QC'
      a 'Needs revision', href: needs_revision_admin_observation_path(observation), 'data-method': :put if observation.validation_status == 'QC in progress'
      a 'Ready to publish',  href: ready_for_publication_admin_observation_path(observation), 'data-method': :put if observation.validation_status == 'QC in progress'
    end
    actions

    panel 'Visible columns' do
      render partial: "fields",
             locals: { attributes: %w[active hidden status country fmu location_information observers observation_type
                                      operator governments relevant_operators subcategory
                                      illegality_as_written_by_law legal_reference_illegality
                                      legal_reference_penalties minimum_fine maximum_fine currency penal_servitude
                                      other_penalties indicator_apv severity publication_date actions_taken
                                      details evidence_type evidences evidence_in_the_report concern_opinion pv location_accuracy
                                      lat lng is_physical_place litigation_status report admin_comment monitor_comment
                                      responsible_admin user modified_user modified_user_language created_at updated_at deleted_at] }
    end
  end

  form do |f|
    operator   = object.operator_id.present? ? true : false
    fmu        = object.fmu_id.present? ? true : false
    government = object.government_ids.present? ? true : false

    f.semantic_errors *f.object.errors.keys
    f.inputs 'Management' do
      f.input :responsible_admin, as: :select,
                                  collection: User.joins(:user_permission).where(user_permissions: { user_role: :admin })
    end
    f.inputs 'Info' do
      f.input :id, input_html: { disabled: true }
    end
    f.inputs 'Status' do
      f.input :is_active, input_html: { disabled: true }
      f.input :hidden
      f.input :validation_status
    end
    f.inputs 'Observation Details' do
      f.input :country, input_html: { disabled: true }
      f.input :observation_type, input_html: { disabled: true }
      f.input :subcategory, input_html: { disabled: true }
      f.input :law, collection: Law.by_country_subcategory(object).map { |l| [l.written_infraction, l.id] } rescue ''
      f.input :severity, as: :select,
                         collection: object.subcategory.severities.map { |s| ["#{s.level} - #{s.details.first(80)}", s.id] } rescue ''
      f.input :is_physical_place, input_html: { disabled: true }
      f.input :location_information  if f.object.observation_type == 'operator'
      f.input :fmu, input_html: { disabled: fmu } if f.object.observation_type == 'operator'
      f.input :observers

      f.input :relevant_operator_ids,
              label: 'Relevant Operators',
              as: :select, collection: Operator.all.map { |o| [o.name, o.id] },
              input_html: { multiple: true }
      if f.object.observation_type == 'government'
        f.input :government_ids,
                label: "Governments",
                as: :select,
                collection: Government.all.map { |g| [g.government_entity, g.id] },
                input_html: { disabled: government, multiple: true }
      end
      f.input :operator, input_html: { disabled: operator } if f.object.observation_type == 'operator'
      f.input :publication_date, as: :date_time_picker, picker_options: { timepicker: false }
      f.input :pv
      f.input :location_accuracy, as: :select
      f.input :lat
      f.input :lng
      f.input :actions_taken
      f.input :admin_comment
      f.input :monitor_comment, input_html: { disabled: true }
      f.input :observation_report, as: :select
      f.input :evidence_type, as: :select
      f.input :evidence_on_report, label: 'Evidence in the report'
      f.has_many :observation_documents, new_record: 'Add evidence', heading: 'Evidence' do |t|
        t.input :name
        t.input :attachment
      end
    end
    f.inputs 'Translated fields' do
      f.translated_inputs switch_locale: false do |t|
        t.input :details
        t.input :concern_opinion
        t.input :litigation_status
      end
    end
    f.actions
  end

  show do
    attributes_table do
      row :is_active
      row :hidden
      tag_row :validation_status
      row :country
      row :observation_type
      row :subcategory
      row :law
      row :severity do |o|
        o.severity&.details
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
      if resource.governments.present?
        row :governments do |o|
          list = o.governments.each_with_object([]) do |government, links|
            links << link_to(government.government_entity, admin_government_path(government.id))
          end

          safe_join(list, " ")
        end
      end
      row :relevant_operators do |o|
        list = o.relevant_operators.each_with_object([]) do |operator, links|
          links << link_to(operator.name, admin_producer_path(operator.id))
        end

        safe_join(list, " ")
      end

      row :publication_date
      row :pv
      row :location_accuracy
      row :lat
      row :lng
      if resource.lat.present? && resource.lng.present?
        row :location_on_map do |r|
          render partial: 'map', locals: { center: [r.lng, r.lat], geojson: r.fmu&.geojson, bbox: r.fmu&.bbox }
        end
      end
      row :actions_taken
      row :concern_opinion
      row :observation_report
      row :admin_comment
      row :monitor_comment
      row :responsible_admin
      row :user
      row :modified_user
      row :modified_user_language do |o|
        o.modified_user&.locale
      end
      row :created_at
      row :updated_at
      row :deleted_at
    end

    active_admin_comments
  end
end
