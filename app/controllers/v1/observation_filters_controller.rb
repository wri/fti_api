
module V1
  class ObservationFiltersController < ApplicationController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate

    def index
      annexes = [{id: 'operator', name: 'Operator'}, {id: 'governance', name: 'Governance'}]
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
      #levels = Severity.all.includes(:translations).with_translations(I18n.available_locales).pluck(:level).sort
      severities =[{id: 0, name: 'Unknown'}, {id: 1, name: 'Low'}, {id: 2, name: 'Medium'}, {id: 3, name: 'High'}]

      filters = {
          'types': annexes,
          'country_ids': country_ids,
          'fmu_ids': fmu_ids,
          'years': years,
          'observer_ids': observer_ids,
          'category_ids': category_ids,
          'severities': severities
      }.to_json

      render json: filters
    end

  end
end
