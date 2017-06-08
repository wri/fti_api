
module V1
  class ObservationFiltersController < ApplicationController
    include ErrorSerializer
    include ApiUploads

    skip_before_action :authenticate

    def index
      annexes = %w(AnnexOperator AnnexGovernance)
      countries = Country.all.includes(:translations).with_translations(I18n.available_locales).pluck(:id, :iso, :name)
        .map{|x| {id: x[0], iso: x[1], name: x[2]}}
      fmus = Fmu.all.includes(:translations).with_translations(I18n.available_locales).pluck(:id, :name)
        .map{|x| {id: x[0], name: x[0]}}
      years = Observation.pluck(:publication_date).map{|x| x.year}.uniq.sort
      monitors = Observer.all.includes(:translations).with_translations(I18n.available_locales).pluck(:id, :name)
        .map{|x| {id: x[0], name: x[1]}}
      categories = Category.all.includes(:translations).with_translations(I18n.available_locales).pluck(:id, :name)
        .map{|x| {id: x[0], name: x[1]}}
      levels = Severity.all.includes(:translations).with_translations(I18n.available_locales).pluck(:level).sort

      filters = {
          'type': annexes,
          'country': countries,
          'fmu': fmus,
          'years': years,
          'monitors': monitors,
          'categories': categories,
          'levels': levels
      }.to_json

      render json: filters
    end

  end
end
