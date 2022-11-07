# frozen_string_literal: true

module V1
  class ObservationFiltersController < ApiController
    include ErrorSerializer

    skip_before_action :authenticate

    def tree
      years = Observation.pluck(:publication_date).map{ |x| x.year }.uniq.sort
        .map{ |x| { id: x, name: x } }

      severities = [
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

    private

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
      Government.active.with_translations(I18n.locale).map do |x|
        { id: x.id, name: x.government_entity }
      end.sort_by { |x| x[:name] }
    end

    def operator_ids
      having_published_observations = Observation.published.select(:operator_id).distinct.pluck(:operator_id)
      name_column = Arel.sql('operator_translations.name')

      Operator
        .where(id: having_published_observations)
        .includes(:fmus)
        .with_translations(I18n.locale)
        .group(:id, name_column)
        .order(name_column)
        .pluck(:id, name_column, 'array_agg(fmus.id) fmu_ids')
        .map do |x|
          { id: x[0], name: x[1], fmus: x[2] }
        end
    end

    def subcategory_ids
      Subcategory.with_translations(I18n.locale).map do |x|
        { id: x.id, name: x.name }
      end.sort_by { |x| x[:name] }
    end

    def category_ids
      Category.all.with_translations(I18n.locale).includes(:subcategories).map do |x|
        { id: x.id, name: x.name, subcategories: x.subcategories.pluck(:id).uniq }
      end.sort_by { |x| x[:name] }
    end

    def fmu_ids
      name_column = Arel.sql("fmu_translations.name")
      Fmu.all.with_translations(I18n.locale).order('fmu_translations.name asc').pluck(:id, name_column).map{ |x| { id: x[0], name: x[1] } }
    end

    def observer_ids
      having_published_observations = Observation.published.joins(:observers).select(:observer_id).distinct.pluck(:observer_id)

      Observer
        .active
        .where(id: having_published_observations)
        .with_translations(I18n.locale)
        .map{ |x| { id: x.id, name: x.name } }
        .sort_by { |x| x[:name] }
    end

    def country_ids
      Country
        .with_translations(I18n.locale)
        .with_observations(Observation.published)
        .map do  |x|
          {
            id: x.id, iso: x.iso, name: x.name,
            operators: x.operators.pluck(:id).uniq,
            observers: x.observations.joins(:observers).pluck(:observer_id).uniq,
            fmus: x.fmus.pluck(:id).uniq,
            governments: x.governments.pluck(:id).uniq
          }
        end
        .sort_by { |x| x[:name] }
    end
  end
end
