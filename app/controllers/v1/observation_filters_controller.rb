# frozen_string_literal: true

module V1
  class ObservationFiltersController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate

    FILTER_TYPES = {
        'validation-status': { type: /Published \(no comments\)|Published \(not modified\)|Published \(modified\)/ },
        'observation-type': { type: /operator|government/ },
        'country-id': { type: Integer },
        'fmu-id': { type: Integer },
        'year': { type: Integer, query: 'EXTRACT(year FROM observations.publication_date) IN ' },
        'observer-id': { type: Integer, query: 'observers.id IN ' },
        'category-id': { type: Integer, query: 'categories.id IN ' },
        'subcategory-id': { type: Integer },
        'severity-level': { type: Integer, query: 'severities.level IN ' },
        'operator': { type: Integer },
        'observation-report.id': { type: Integer, query: 'observation_reports.id IN ' },
        'source': { type: Integer }
    }.freeze

    OBS_TYPES = {
        'operator' => { id: 'operator', name: I18n.t('filters.operator') },
        'government' => { id: 'government', name: I18n.t('filters.governance') }
    }.freeze

    SEVERITIES = {
        0 => { id: 0, name: I18n.t('filters.unknown') },
        1 => { id: 1, name: I18n.t('filters.low') },
        2 => { id: 2, name: I18n.t('filters.medium') },
        3 => { id: 3, name: I18n.t('filters.high') }
    }.freeze

    def tree
      years = Observation.pluck(:publication_date).map{ |x| x.year }.uniq.sort
                  .map{ |x| { id: x, name: x } }

      severities =[
          { id: 0, name: I18n.t('filters.unknown') },
          { id: 1, name: I18n.t('filters.low') },
          { id: 2, name: I18n.t('filters.medium') },
          { id: 3, name: I18n.t('filters.high') }
      ]

      sources = [
          { id: 1, name: I18n.t('filters.company') },
          { id: 2, name: I18n.t('filters.forest_atlas') },
          { id: 3, name: I18n.t('filters.other') }
      ]

      filters = {
          'validation_status': validation_statuses,
          'observation_type': types,
          'country_id': country_ids,
          'fmu_id': fmu_ids,
          'years': years,
          'observer_id': observer_ids,
          'category_id': category_ids,
          'subcategory_id': subcategory_ids,
          'severity_level': severities,
          'operator': operator_ids,
          'government': government_ids,
          'observation-report': report_ids,
          'source': sources
      }.to_json

      render json: filters
    end

    def index
      records = filtered_records

      observation_types = records.pluck(:observation_type).uniq.map { |o| OBS_TYPES[o] }

      country_ids = Country.with_translations.where(id: records.pluck(:country_id).uniq).map{ |x| { id: x.id, iso: x.iso, name: x.name } }.sort_by { |x| x[:name] }
      fmu_ids = records.joins(:fmu)
                  .joins("JOIN fmu_translations on fmu_translations.fmu_id = fmus.id and fmu_translations.locale = '#{I18n.locale}'")
                    .select('fmus.id, fmu_translations.name').group('fmus.id, fmu_translations.id')
                    .map{ |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
      operator_ids = records.joins(:operator)
                       .joins("JOIN operator_translations on operator_translations.operator_id = operators.id and operator_translations.locale = '#{I18n.locale}'")
                         .select("operators.id, operator_translations.name").group('operators.id, operator_translations.name')
                         .map { |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
      years = records.pluck(:publication_date).uniq.map{ |x| x.year }.uniq.sort.map{ |x| { id: x, name: x } }
      observer_ids = Observer.where(id: records.joins(:observers).select('observers.id').uniq)
                       .map{ |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
      subcategory_ids = Subcategory.where(id: records.pluck(:subcategory_id).uniq)
      category_ids = Category.where(id: subcategory_ids.select(:category_id).uniq)
                       .map{ |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
      subcategory_ids = subcategory_ids.with_translations.map{ |o| { id: o.id, name: o.name } }
      severities = records.joins(:severity).pluck('severities.level').uniq.map { |x| SEVERITIES[x] }
      report_ids = records.joins(:observation_report).select('observation_reports.id, observation_reports.title').uniq
                     .map { |x| { id: x.id, name: x.title } }.sort_by { |x| x[:title] }

      filters = {
          observation_type: observation_types,
          country_id: country_ids,
          fmu_id: fmu_ids,
          years: years,
          observer_id: observer_ids,
          category_id: category_ids,
          subcategory_id: subcategory_ids,
          severity_level: severities,
          operator: operator_ids,
          'observation-report': report_ids
      }.to_json

      render json: filters
    end

    def csv
      filters = observation_filters
      send_data to_csv(filters), filename: "observations-#{Date.today}.csv"
    end

    private

    # TODO Redo this with AR. This code is a mess
    def to_csv(filters)
      records = Observation.with_translations.
          joins(:severity, :observers, subcategory: :category).active
      filters.each do |filter|
        records = records.where(filter)
      end

      observations = records.to_a
      countries = model_hash(Country, [:id, :name], records, true )
      fmus = model_hash(Fmu, [:id, :name], records, true )
      observers = model_hash(Observer, ['observations.id', :name], records, true, true )
      operators = model_hash(Operator, [:id, :name], records, true )
      governments = model_hash(Government, ['observations.id', :government_entity], records, true, true )
      subcategories = model_hash(Subcategory, [:id, :name], records, true)
      laws = model_hash(Law, [:id, :written_infraction], records, false)
      severities = model_hash(Severity, [:id, :level], records, true)
      reports = model_hash(ObservationReport, [:id, :title], records, false)
      users = model_hash(User, [:id, :name], records, false)

      CSV.generate(headers: true) do |csv|
        csv << %w(id is_active hidden observation_type
                  status country fmu observers operator governments
                  subcategory law severity publication_date actions_taken details
                  evidence_type concern_opinion report user created_at updated_at)
        observations.each do |obs|
          csv << [obs.id, obs.is_active, obs.hidden, obs.observation_type, obs.status,
                  v(countries, obs.country_id),
                  v(fmus, obs.fmu_id),
                  v(observers, obs.id),
                  v(operators, obs.operator_id),
                  v(governments, obs.id),
                  v(subcategories, obs.subcategory_id),
                  v(laws, obs.law_id),
                  v(severities, obs.severity_id),
                  obs.publication_date, obs.actions_taken, obs.details, obs.evidence_type,
                  obs.concern_opinion,
                  v(reports, obs.observation_report_id),
                  v(users, obs.user_id),
                  obs.created_at, obs.updated_at]
        end
      end
    end

    def v(hash, key)
      hash[key]
    rescue StandardError
      nil
    end

    def model_hash(model, fields, records, translations = false, has_many = false)
      if has_many
        array = model.joins(:observations)
                     .merge(records)
                     .pluck(*fields)
                     .uniq
                     .map{ |x| { x[0] => x[1] } }
        hash = {}
        array.each do |elem|
          if hash[elem.keys.first].blank?
            hash[elem.keys.first] = elem.values.first
          else
            hash[elem.keys.first] = hash[elem.keys.first] + ' ' + elem.values.first
          end
        end
        return hash
      end
      if translations
        return model.with_translations.joins(:observations)
          .merge(records)
          .pluck(*fields)
          .map{ |x| { x[0] => x[1] } }
          .reduce(:merge)
      end
      model.joins(:observations)
          .merge(records)
          .pluck(*fields)
          .map{ |x| { x[0] => x[1] } }
          .reduce(:merge)
    end

    def observation_filters
      filters = []

      params['filter']&.each do |k, v|
        next unless valid_params(k, v)

        # Different behavior for when the model attribute is an enum
        if Observation.public_methods.include? k.pluralize.underscore.to_sym
          enum_values = v.split(',').map { |e| Observation.public_send(k.pluralize.underscore.to_sym)[e.to_sym] }
          filters << { k.underscore => enum_values }
        elsif query = FILTER_TYPES[k.dasherize.to_sym][:query]
          filters <<  query + "(#{v})"
        else
          filters << { k.underscore => v.split(',') }
        end
      end
      filters
    end

    def filtered_records
      records = Observation.all.includes(:translations, :law, :severity, :observation_report, country: :translations,
                                                                                              fmu: :translations,
                                                                                              subcategory: :translations,
                                                                                              operator: :translations,
                                                                                              governments: :translations,
                                                                                              observers: :translations)

      params['filter']&.each do |k, v|
        next unless valid_params(k, v)

        # Different behavior for when the model attribute is an enum
        if Observation.public_methods.include? k.pluralize.underscore.to_sym
          enum_values = v.split(',').map { |e| Observation.public_send(k.pluralize.underscore.to_sym)[e.to_sym] }
          records = records.where(k.underscore => enum_values)
        elsif query = FILTER_TYPES[k.dasherize.to_sym][:query]
          records = records.where(query + "(#{v})")
        else
          records = records.where(k.underscore => v.split(','))
        end
      end
      records
    end

    def types
      categories_operator = Category.where(category_type: 'operator').pluck(:id)
      categories_government = Category.where(category_type: 'government').pluck(:id)
      [{ id: 'operator', name: I18n.t('filters.operator'), categories: categories_operator.uniq },
       { id: 'government', name: I18n.t('filters.governance'), categories: categories_government.uniq }]
    end

    def report_ids
      ObservationReport.all.map { |x| { id: x.id, name: x.title } }.sort_by { |x| x[:title] }
    end

    def validation_statuses
      [
          { id: 7, name: "Published (no comments)" },
          { id: 8, name: "Published (not modified)" },
          { id: 9, name: "Published (modified)" }
      ].sort_by { |x| x[:name] }
    end

    def government_ids
      Government.active.with_translations.map do |x|
        { id: x.id, name: x.government_entity }
      end.sort_by { |x| x[:name] }
    end

    def operator_ids
      Operator.active.with_translations.includes(:fmus).map do |x|
        { id: x.id, name: x.name, fmus: x.fmus.pluck(:id) }
      end.sort_by { |x| x[:name] }
    end

    def subcategory_ids
      Subcategory.with_translations.map do |x|
        { id: x.id, name: x.name }
      end.sort_by { |x| x[:name] }
    end

    def category_ids
      Category.all.with_translations.includes(:subcategories).map do |x|
        { id: x.id, name: x.name, subcategories: x.subcategories.pluck(:id).uniq }
      end.sort_by { |x| x[:name] }
    end

    def fmu_ids
      Fmu.all.with_translations.map{ |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
    end

    def observer_ids
      Observer.all.with_translations.map{ |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
    end

    def country_ids
      Country.with_translations.with_active_observations
          .map do  |x|
            {
              id: x.id, iso: x.iso, name: x.name,
              operators: x.operators.pluck(:id).uniq,
              observers: x.observations.joins(:observers).pluck(:observer_id).uniq,
              fmus: x.fmus.pluck(:id).uniq,
              governments: x.governments.pluck(:id).uniq
            }
          end.sort_by { |x| x[:name] }
    end

    def valid_params(name, value)
      return false unless name.present? && value.present?
      return false unless param = FILTER_TYPES.dig(name.dasherize.to_sym, :type)
      return false unless values = value&.split(',')
      return false unless (values.select { |x| ObservationFiltersController.is_of_type(param, x) }).count == values.count

      true
    end

    # TODO: Hack. Modify to use refinements
    def self.is_of_type(type, value)
      if type == Integer
        return true if value.to_i.to_s == self
      end
      type === value
    end
  end
end
