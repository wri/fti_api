# frozen_string_literal: true

module ScoreEvolutionHelper
  HIDDEN_SCORE = {dataset: {hidden: true}}.freeze

  # Builds line chart series of the dashboard statistic collection, one point per date.
  # Scores is a hash of a count column to its chartkick options, :name overrides
  # the humanized column name.
  # example
  # score_evolution_scores(collection, total_count: {name: "Reports"}, valid_count: HIDDEN_SCORE)
  def score_evolution_scores(collection, scores)
    rows_by_date = score_evolution_rows_by_date(collection)

    scores.map do |column, options|
      {
        name: options[:name] || active_admin_config.resource_class.human_attribute_name(column),
        data: rows_by_date.transform_values { |rows| rows.map(&column).max },
        **{dataset: {id: column.to_s}}.deep_merge(options.except(:name))
      }
    end
  end

  private

  # only the all countries rollup rows are charted, unless a country is selected
  def score_evolution_rows_by_date(collection)
    rows = if params.dig(:q, :by_country).present?
      collection
    else
      collection.select { |r| r.country_id.nil? }
    end

    rows.group_by { |r| r.date.to_date }
  end
end
