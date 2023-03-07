# frozen_string_literal: true

ActiveAdmin.register ObservationReportStatistic, as: 'Observation Reports Dashboard' do
  extend BackRedirectable

  menu false

  actions :index

  filter :by_country, label: proc{ I18n.t('activerecord.models.country.one') }, as: :select,
                      collection: -> {
           [[I18n.t('active_admin.producer_documents_dashboard_page.all_countries'), 'null']] +
             Country.with_at_least_one_report.order(:name).map { |c| [c.name, c.id] }
         }
  filter :observer, label: proc{ I18n.t('activerecord.models.observer') }, as: :select, multiple: true, collection: -> { Observer.where(id: ObservationReportStatistic.all.select(:observer_id).distinct).order(:name) }
  filter :date

  index title: I18n.t('active_admin.observation_reports_dashboard_page.name') do
    column :date, sortable: false do |resource|
      resource.date.to_date
    end
    column :country do |resource|
      if resource.country.nil?
        I18n.t('active_admin.producer_documents_dashboard_page.all_countries')
      else
        link_to resource.country.name, admin_country_path(resource.country)
      end
    end
    column :total_count, label: I18n.t('active_admin.observation_reports_dashboard_page.total_count'), sortable: false
    returned_observers.map do |o|
      column o.name, "o_#{o.id}" do |res|
        res.send("o_#{o.id}") || '0'
      end
    end
    show_on_chart = if params.dig(:q, :by_country).present?
                      collection
                    else
                      collection.select { |r| r.country_id.nil? }
                    end
    grouped_sod = show_on_chart.group_by(&:date)

    render partial: 'score_evolution', locals: {
      scores: [
        { name: I18n.t('active_admin.observation_reports_dashboard_page.reports'), data: grouped_sod.map { |date, data| { date.to_date => data.map(&:total_count).max } }.reduce(&:merge) }
      ]
    }
  end

  csv do
    column :date do |resource|
      resource.date.strftime('%d/%m/%Y')
    end
    column :country, &:country_name
    column :total_count
    returned_observers.map do |o|
      column o.name do |res|
        res.send("o_#{o.id}") || '0'
      end
    end
  end

  controller do
    skip_before_action :restore_search_filters
    skip_after_action :save_search_filters
    before_action :set_default_filters

    helper_method :returned_observers

    def set_default_filters
      return unless request.format.html?

      params[:q] ||= {}
      params[:q][:observer_id_null] = true if params.dig(:q, :observer_id_in).blank?
    end

    def find_collection(options = {})
      col = if params.dig(:q, :date_gteq).present?
              ObservationReportStatistic.from_date(params[:q][:date_gteq])
            else
              ObservationReportStatistic.all
            end
      observer_ids = Observer.with_at_least_one_report.pluck(:id)

      @search = col.ransack(params[:q] || {})
      @search.result.select(
        :date,
        :country_id,
        "string_agg(observer_id::text, ',') as all_observer_ids",
        %{
            (select total_count
             from observation_report_statistics o2
             where o2.date <= observation_report_statistics.date
             and coalesce(o2.country_id::text, 'null') = coalesce(observation_report_statistics.country_id::text, 'null')
             and o2.observer_id is null
             order by o2.date desc
             limit 1
            ) as total_count
        },
        *observer_ids.map do |o_id|
          "sum(total_count) filter (where observer_id = #{o_id}) as o_#{o_id}"
        end
      )
        .group(:date, :country_id)
        .order('date desc, country_id NULLS first')
        .includes(country: :translations)
        .page(params[:page])
        .per(10000)
    end

    def returned_observers
      ids = collection.map(&:all_observer_ids).compact.map { |ids| ids.split(',') }.flatten.uniq.compact
      Observer.where(id: ids).with_translations
    end
  end
end
