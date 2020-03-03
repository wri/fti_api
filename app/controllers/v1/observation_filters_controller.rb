# frozen_string_literal: true

module V1
  class ObservationFiltersController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate

    def index
      types = [{ id: 'operator', name: I18n.t('filters.operator') }, { id: 'government', name: I18n.t('filters.governance') }]
      country_ids = Country.with_observations.joins(:translations)
                        .map{ |x| { id: x.id, iso: x.iso, name: x.name } }.sort_by { |x| x[:name] }
      fmu_ids = Fmu.all.joins(:translations).map{ |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
      years = Observation.pluck(:publication_date).map{ |x| x.year }.uniq.sort
                  .map{ |x| { id: x, name: x } }
      observer_ids = Observer.all.includes(:translations).map{ |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
      category_ids = Category.all.includes(:translations).map{ |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
      severities =[
          { id: 0, name: I18n.t('filters.unknown') },
          { id: 1, name: I18n.t('filters.low') },
          { id: 2, name: I18n.t('filters.medium') },
          { id: 3, name: I18n.t('filters.high') }
]
      operator_ids = Operator.active.includes(:translations).map { |x| { id: x.id, name: x.name } }.sort_by { |x| x[:name] }
      reports_ids = ObservationReport.all.map { |x| { id: x.id, name: x.title } }.sort_by { |x| x[:title] }


      filters = {
          'observation_type': types,
          'country_id': country_ids,
          'fmu_id': fmu_ids,
          'years': years,
          'observer_id': observer_ids,
          'category_id': category_ids,
          'severity_level': severities,
          'operator': operator_ids,
          'observation-report': reports_ids
      }.to_json

      render json: filters
    end

  end
end
