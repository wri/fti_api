# frozen_string_literal: true

# shared behaviour of the daily snapshot statistic models powering admin dashboards
module DailyStatistic
  extend ActiveSupport::Concern

  included do
    belongs_to :country, optional: true

    validates :date, presence: true
  end

  class_methods do
    # columns identifying a single statistic series, implemented by the models
    def statistic_dimensions
      raise NotImplementedError
    end

    # stats after the given date plus the snapshot at that date,
    # so charts always start at the beginning of the range
    def from_date(date)
      date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)
      from_date_sql = where("date > ?", date_obj.to_fs(:db)).to_sql
      first_rows_sql = at_date(date_obj).to_sql

      from("(#{from_date_sql} UNION #{first_rows_sql}) as #{table_name}")
    end

    # latest stat of every series as of the given date, re-dated to that date;
    # rows are stored only when counters change, so the last row carries the current state
    def at_date(date)
      return none if date.blank?

      date_obj = date.respond_to?(:strftime) ? date : Date.parse(date)
      # keep schema column order, from_date unions this with a select *
      select_columns = column_names.map { |c| (c == "date") ? ":date_obj::date as date" : c }

      query = <<~SQL
        (select
          #{select_columns.join(", ")}
         from
         (select row_number() over (partition by #{statistic_dimensions.join(", ")} order by date desc), *
          from #{table_name}
          where date <= :date_obj
         ) as stats_by_date
         where stats_by_date.row_number = 1
        ) as #{table_name}
      SQL

      from(ActiveRecord::Base.sanitize_sql([query, {date_obj: date_obj.to_fs(:db)}]))
    end

    def ransackable_scopes(auth_object = nil)
      [:by_country]
    end

    def by_country(country_id)
      return all if country_id.nil?
      return where(country_id: nil) if country_id == "null"

      where(country_id: country_id)
    end
  end

  def previous_stat
    self.class
      .where(attributes.slice(*self.class.statistic_dimensions))
      .where("date < ?", date)
      .order(:date)
      .last
  end

  def country_name
    return country.name if country.present?

    "All Countries"
  end

  # same series with the same counters, generators use it to move the date
  # of the previous stat forward instead of storing an unchanged snapshot
  def ==(other)
    return false unless other.is_a?(self.class)

    (self.class.column_names - %w[id date created_at updated_at]).all? do |attr|
      send(attr) == other.send(attr)
    end
  end
end
