# frozen_string_literal: true

module ScoreEvolutionHelper
  HIDDEN_SCORE = {dataset: {hidden: true}}.freeze

  # Same colors as the matching status tags in active_admin.scss; too-light tag colors are darkened
  SCORE_COLORS = {
    not_provided_count: "#98a2b3",
    pending_count: "#ff9900",
    invalid_count: "#ff0000",
    valid_and_expired_count: "#317a4b",
    valid_count: "#08a510",
    expired_count: "#772222",
    not_required_count: "#aa8888",
    created: "#6fb3cc",
    ready_for_qc: "#08a1cc",
    qc_in_progress: "#112ead",
    approved: "#08a510",
    rejected: "#ff0000",
    needs_revision: "#8a333a",
    ready_for_publication: "#7eb378",
    published_no_comments: "#0b6301",
    published_not_modified: "#77801b",
    published_modified: "#256103",
    published_all: "#317a4b",
    total_count: "#317a4b"
  }.freeze

  CHART_AXIS = {color: "#667085", font: {family: "Inter, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif", size: 11}}.freeze

  CHART_OPTIONS = {
    curve: false,
    thousands: ",",
    dataset: {borderWidth: 2, pointRadius: 0, pointHoverRadius: 4, pointHitRadius: 4},
    library: {
      interaction: {mode: "index", intersect: false},
      plugins: {
        legend: {
          labels: {usePointStyle: true, pointStyle: "circle", boxWidth: 8, boxHeight: 8, padding: 14, color: "#344054", font: CHART_AXIS[:font].merge(size: 12)}
        },
        tooltip: {
          mode: "index", intersect: false, displayColors: true, usePointStyle: true, boxWidth: 8, boxHeight: 8, boxPadding: 6,
          padding: 12, bodySpacing: 6, titleMarginBottom: 8, cornerRadius: 6, backgroundColor: "#101828",
          titleFont: CHART_AXIS[:font].merge(size: 13, weight: "600"), bodyFont: CHART_AXIS[:font].merge(size: 12)
        }
      },
      scales: {
        x: {grid: {display: false}, border: {color: "#e4e7ec"}, ticks: CHART_AXIS},
        y: {grid: {color: "#f1f3f6"}, border: {display: false}, ticks: CHART_AXIS}
      }
    }
  }.freeze

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
        data: rows_by_date.transform_values { |row| row.public_send(column) },
        **{color: SCORE_COLORS[column], dataset: {id: column.to_s, backgroundColor: SCORE_COLORS[column]}.compact}.compact.deep_merge(options.except(:name))
      }
    end
  end

  private

  # only the all countries rollup rows are charted, unless a country is selected,
  # either way statistics of a single country give one row per date
  def score_evolution_rows_by_date(collection)
    rows = if params.dig(:q, :by_country).present?
      collection
    else
      collection.select { |r| r.country_id.nil? }
    end

    rows.index_by { |r| r.date.to_date }
  end
end
