# frozen_string_literal: true

ActiveAdmin.register ObservationStatistic, as: 'Observations Dashboard' do
  extend BackRedirectable
  back_redirect

  menu false

  actions :index

  filter :by_country, label: 'Country', as: :select, collection: [['All Countries', 'null']] + Country.where(id: Observation.pluck(:country_id)).map { |c| [c.name, c.id] }
  filter :operator, label: 'Operator', as: :select, collection: Operator.where(id: Observation.pluck(:operator_id))
  filter :fmu_forest_type_eq, label: 'Forest Type', as: :select, collection: Fmu::FOREST_TYPES.map { |ft| [ft.last[:label], ft.last[:index]] }
  # filter :category,
  #   label: 'Category', as: :select,
  #   collection: -> { Category.with_translations(I18n.locale).order('category_translations.name') }
  filter :subcategory,
    label: 'Subcategory', as: :select,
    collection: -> { Subcategory.with_translations(I18n.locale).order('subcategory_translations.name') }
  filter :severity_level, as: :select, collection: [['Unknown', 0],['Low', 1], ['Medium', 2], ['High', 3]]
  filter :validation_status, as: :select, collection: Observation.validation_statuses.sort
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
    column :operator do |r|
      if r.operator.nil?
        'All Operators'
      else
        link_to r.operator.name, admin_producer_path(r.operator)
      end
    end
    column :fmu_forest_type do |r|
      if r.fmu_forest_type.nil?
        'All Forest Types'
      else
        Fmu.forest_types.key(r.fmu_forest_type)
      end
    end
    column :severity_level do |r|
      if r.severity_level.nil?
        'All Levels'
      else
        r.severity_level
      end
    end
    column :validation_status do |r|
      if r.validation_status.nil?
        'All Statuses'
      else
        r.validation_status
      end
    end
    column :subcategory do |r|
      if r.subcategory.nil?
        'All Subcategories'
      else
        link_to r.subcategory.name, admin_subcategory_path(r.subcategory)
      end
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

    def find_collection(options = {})
      date_from = params.dig(:q, :date_gteq) || Observation.order(:created_at).first.created_at.to_date
      date_to = params.dig(:q, :date_lteq) || Date.today.to_date
      country_id = params.dig(:q, :by_country)
      operator_id = params.dig(:q, :operator_id_eq)
      subcategory_id = params.dig(:q, :subcategory_id_eq)
      validation_status = params.dig(:q, :validation_status_eq)
      severity_level = params.dig(:q, :severity_level_eq)
      forest_type = params.dig(:q, :fmu_forest_type_eq)

      filters = [
        country_id.nil? || country_id == 'null' ? nil : "country_id = #{country_id}",
        operator_id.nil? ? nil : "operator_id = #{operator_id}",
        validation_status.nil? ? nil : "validation_status = #{validation_status}",
        forest_type.nil? ? nil : "forest_type = #{forest_type}",
        severity_level.nil? ? nil : "level = #{severity_level}",
        subcategory_id.nil? ? nil : "subcategory_id = #{subcategory_id}"
      ].compact.join(' AND ')
      select = [
        operator_id.nil? ? nil : "#{operator_id} as operator_id",
        validation_status.nil? ? nil : "#{validation_status} as validation_status",
        severity_level.nil? ? nil : "#{severity_level} as severity_level",
        subcategory_id.nil? ? nil : "#{subcategory_id} as subcategory_id",
        forest_type.nil? ? nil : "#{forest_type} as forest_type"
      ].compact.join(',')

      sql = <<~SQL
        with dates as (
          SELECT date_trunc('day', dd)::date as date
          FROM generate_series
              ( '#{date_from.to_s(:db)}'::timestamp
              , '#{date_to.to_s(:db)}'::timestamp
              , '1 day'::interval) dd
        ),
        grouped as (
          select
            date,
            country_id,
            count(*) as total_count
          from
          dates
          left join lateral
            (
              select o.*, s.level, f.forest_type from observations o
              left join fmus f on f.id = o.fmu_id
              inner join severities s on s.id = o.severity_id
              where o.created_at <= dates.date
            ) as observations_by_date on 1=1
          #{filters.present? ? 'where ' + filters : ''}
          group by date, rollup(country_id)
        )
        select
          date,
          country_id,
          #{select.present? ? select + ',' : ''}
          total_count
        from (
          select
            *,
            LAG(total_count,1) OVER (
              partition by country_id
              ORDER BY date
            ) prev_total
            from grouped
        ) as total_c
        where
          (prev_total is null or prev_total != total_count or date = '#{date_to.to_s(:db)}}' or date = '#{date_from.to_s(:db)}}')
          AND (#{country_id.nil? || country_id == 'null' ? '1=1' : 'country_id is not null'})
          AND (#{country_id == 'null' ? 'country_id is null' : '1=1'})
        order by date desc
      SQL

      collection = ActiveRecord::Base.connection.execute(sql).to_a.map do |row|
        ObservationStatistic.new(
          date: row['date'],
          country_id: row['country_id'],
          total_count: row['total_count'],
          operator_id: row['operator_id'],
          subcategory_id: row['subcategory_id'],
          validation_status: row['validation_status'],
          fmu_forest_type: row['forest_type'],
          severity_level: row['severity_level']
        )
      end

      @search = ObservationStatistic.search(params[:q] || {})
      Kaminari.paginate_array(collection).page(1).per(100000)
    end
  end
end
