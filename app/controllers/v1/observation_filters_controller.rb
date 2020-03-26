# frozen_string_literal: true

module V1
  class ObservationFiltersController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate

    FILTER_TYPES = {
        'observation-type': { type: /operator|government/ },
        'country-id': { type: Integer },
        'fmu-id': { type: Integer },
        'year': { type: Integer, query: 'EXTRACT(year FROM observations.publication_date) IN ' },
        'observer-id': { type: Integer, query: 'observers.id IN ' },
        'category-id': { type: Integer, query: 'categories.id IN ' },
        'subcategory-id': { type: Integer },
        'severity-level': { type: Integer, query: 'severities.level IN ' },
        'operator': { type: Integer },
        'observation-report.id': { type: Integer, query: 'observation_reports.id IN ' }
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


    def index
      records = Observation.all.joins(:observers, :severity, :observation_report, subcategory: :category)
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

    private

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
        return true if Integer(value) rescue false
      end
      type === value
    end
  end
end
