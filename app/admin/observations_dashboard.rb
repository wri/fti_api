# frozen_string_literal: true

ActiveAdmin.register ObservationStatistic, as: 'Observations Dashboard' do
  extend BackRedirectable
  back_redirect

  menu false

  actions :index

  filter :by_country, label: 'Country', as: :select, collection: [['All Countries', 'null']] + Country.where(id: Observation.pluck(:country_id)).map { |c| [c.name, c.id] }
  filter :operator, label: 'Operator', as: :select, collection: Operator.where(id: Observation.pluck(:operator_id))
  filter :fmu_forest_type_eq, label: 'Forest Type', as: :select, collection: Fmu::FOREST_TYPES.map { |ft| [ft.last[:label], ft.last[:index]] }
  filter :category,
         label: 'Category', as: :select,
         collection: -> { Category.with_translations(I18n.locale).order('category_translations.name') }
  filter :subcategory,
         label: 'Subcategory', as: :select,
         collection: -> { Subcategory.with_translations(I18n.locale).order('subcategory_translations.name') }
  filter :severity_level, as: :select, collection: [['Unknown', 0],['Low', 1], ['Medium', 2], ['High', 3]]
  filter :validation_status, as: :select, collection: ObservationStatistic.validation_statuses.sort
  filter :hidden
  filter :is_active
  filter :date

  index do
    column :date, sortable: false do |resource|
      resource.date.to_date
    end
    column :country, sortable: false do |resource|
      if resource.country.nil?
        'All Countries'
      else
        link_to resource.country.name, admin_country_path(resource.country)
      end
    end
    column :operator, sortable: false do |r|
      if r.operator.nil?
        'All Operators'
      else
        link_to r.operator.name, admin_producer_path(r.operator)
      end
    end
    column :fmu_forest_type, sortable: false do |r|
      if r.fmu_forest_type.nil?
        'All Forest Types'
      else
        Fmu.forest_types.key(r.fmu_forest_type)
      end
    end
    column :severity_level, sortable: false do |r|
      r.severity_level.presence || 'All Levels'
    end
    column :validation_status, sortable: false do |r|
      r.validation_status.presence || 'All Statuses'
    end
    column :category do |r|
      if r.category.nil?
        'All Categories'
      else
        link_to r.category.name, admin_category_path(r.category)
      end
    end
    column :subcategory do |r|
      if r.subcategory.nil?
        'All Subcategories'
      else
        link_to r.subcategory.name, admin_subcategory_path(r.subcategory)
      end
    end
    column :is_active do |r|
      r.is_active.presence || 'Any'
    end
    column :hidden do |r|
      r.hidden.presence || 'Any'
    end
    column :total_count, sortable: false
    show_on_chart = if params.dig(:q, :by_country).present?
                      collection
                    else
                      collection.select { |r| r.country_id.nil? }
                    end
    grouped_sod = show_on_chart.group_by(&:date)

    render partial: 'score_evolution', locals: {
      scores: [
        { name: 'Observations', data: grouped_sod.map { |date, data| { date.to_date => data.map(&:total_count).max } }.reduce(&:merge) }
      ]
    }
  end

  csv do
    column :date do |resource|
      resource.date.strftime('%d/%m/%Y')
    end
    column :country, &:country_name
    column :operator do |r|
      if r.operator.nil?
        'All Operators'
      else
        r.operator.name
      end
    end
    column :fmu_forest_type do |r|
      if r.fmu_forest_type.nil?
        'All Forest Types'
      else
        Fmu.forest_types.key(r.fmu_forest_type)
      end
    end
    column :validation_status do |r|
      if r.validation_status.nil?
        'All Statuses'
      else
        r.validation_status
      end
    end
    column :category do |r|
      if r.category.nil?
        'All Categories'
      else
        r.category.name
      end
    end
    column :subcategory do |r|
      if r.subcategory.nil?
        'All Subcategories'
      else
        r.subcategory.name
      end
    end
    column :severity_level
    column :total_count
  end

  controller do
    skip_before_action :restore_search_filters
    skip_after_action :save_search_filters
    before_action :set_default_filters

    def set_default_filters
      params[:q] ||= {}
      params[:q][:date_gteq] = 1.year.ago if params.dig(:q, :date_gteq).blank?
    end

    def find_collection(options = {})
      collection = ObservationStatistic.query_dashboard_report(params[:q] || {})
      # keep the ransack to maintain filters in active admin
      @search = ObservationStatistic.search(params[:q] || {})
      # collection must be paged otherwise aa is complaining
      Kaminari.paginate_array(collection).page(1).per(10000)
    end
  end
end
