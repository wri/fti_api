
module V1
  class ObservationFiltersController < ApplicationController
    include ErrorSerializer

    skip_before_action :authenticate

    def index
      types = [{id: 'operator', name: 'Operator'}, {id: 'government', name: 'Government'}]
      country_ids = Country.all.includes(:translations).with_translations(I18n.available_locales).pluck(:id, :iso, :name)
        .map{|x| {id: x[0], iso: x[1], name: x[2]}}
      fmu_ids = Fmu.all.includes(:translations).with_translations(I18n.available_locales).pluck(:id, :name)
        .map{|x| {id: x[0], name: x[1]}}
      years = Observation.pluck(:publication_date).map{|x| x.year}.uniq.sort
        .map{ |x| {id: x, name: x }}
      observer_ids = Observer.all.includes(:translations).with_translations(I18n.available_locales).pluck(:id, :name)
        .map{|x| {id: x[0], name: x[1]}}
      category_ids = Category.all.includes(:translations).with_translations(I18n.available_locales).pluck(:id, :name)
        .map{|x| {id: x[0], name: x[1]}}
      severities =[{id: 0, name: 'Unknown'}, {id: 1, name: 'Low'}, {id: 2, name: 'Medium'}, {id: 3, name: 'High'}]

      filters = {
          'observation_type': types,
          'country_id': country_ids,
          'fmu_id': fmu_ids,
          'years': years,
          'observer_id': observer_ids,
          'category_id': category_ids,
          'severity_level': severities
      }.to_json

      render json: filters
    end

  end
end
