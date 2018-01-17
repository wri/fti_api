# frozen_string_literal: true

module V1
  class ObservationResource < JSONAPI::Resource
    caching

    attributes :observation_type, :publication_date,
               :pv, :is_active, :details, :evidence, :concern_opinion,
               :litigation_status, :lat, :lng,
               :country_id, :fmu_id,
               :subcategory_id, :severity_id, :created_at, :updated_at, :actions_taken, :validation_status

    has_many :species
    has_many :comments
    has_many :photos
    has_many :observation_documents
    has_many :observers
    has_many :relevant_operators

    has_one :country
    has_one :subcategory
    has_one :severity
    has_one :user
    has_one :modified_user
    has_one :operator
    has_one :government
    has_one :law
    has_one :fmu
    has_one :observation_report

    after_create :add_own_observer
    before_save  :set_modified
    before_save  :validate_status

    filters :id, :observation_type, :fmu_id, :country_id,
            :publication_date, :observer_id, :subcategory_id, :years,
            :observation_report, :law, :operator, :government, :subcategory, :is_active, :validation_status

    filter :category_id, apply: ->(records, value, _options) {
      records.joins(:subcategory).where(subcategories: { category_id: value })
    }

    filter :severity_level, apply: ->(records, value, _options) {
      records.joins(:severity).where(severities: { level: value })
    }

    filter :years, apply: ->(records, value, _options) {
      records.where("extract(year from observations.publication_date) in (#{value.map{|x| x.to_i rescue nil}.join(', ')})")
    }

    filter :'observation_report.id', apply: ->(records, value, _options) {
      records.joins(:observation_report).where(observation_reports: { id: value })
    }

    filter :observer_id, apply: ->(records, value, _options) {
      records.joins(:observers).where(observers: { id: value })
    }

    def self.sortable_fields(context)
      super + [:'country.iso', :'severity.level', :'subcategory.name', :'operator.name']
    end

    def custom_links(_)
      { self: nil }
    end

    # This is called in an after save cause in the before save, there are still no relationships present
    # meaning that if there are more users, they'll override the current one

    def add_own_observer
      begin
        user = context[:current_user]
        @model.observers << Observer.find(user.observer_id) if user.observer_id.present?
        @model.user_id = user.id
        @model.save
        # This is added because of the order of the callbacks in JAR
        @model.update_reports_observers
      rescue Exception => e
        Rails.logger.warn "Observation created without user: #{e.inspect}"
      end
    end

    # Saves the last user who modified the observation
    def set_modified
      user = context[:current_user]
      @model.modified_user_id = user.id
    end


    # Makes sure the validation status can be only one of the two: created, ready for revision
    def validate_status
      @model.validation_status = 'Created' unless ['Created', 'Ready for revision'].include?(@model.validation_status)
    end

    # To allow the filtering of results according to the app and user
    # In the portal, only the approved observations should be shown
    # (using the default scope)
    # In the observation tools, the monitors should see theirs

    def self.records(options = {})
      context = options[:context]
      user = context[:current_user]
      app = context[:app]
      if app == 'observations-tool' && user.present?
        if user.observer_id.present?
          Observation.own_with_inactive(user.observer_id)
        elsif user.user_permission.present? && user.user_permission.user_role == 'admin'
          Observation.joins(:translations)
        else
          Observation.active
        end
      else
        Observation.active
      end
    end

    # Adds the locale to the cache
    def self.attribute_caching_context(context)
      {
          locale: context[:locale]
      }
    end
  end
end
