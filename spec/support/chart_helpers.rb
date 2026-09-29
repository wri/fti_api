module ChartHelpers
  # series passed to chartkick in the rendered page, e.g. [{"name" => "Valid", "data" => {"2026-09-08" => 3}}]
  def chart_series(html)
    json = html[/new Chartkick\["LineChart"\]\("chart-\d+", (\[.*?\]), \{/m, 1]
    json ? JSON.parse(json) : []
  end

  # chartkick serializes series data hashes as [[date, value], ...] pairs
  def chart_dates(html)
    data = chart_series(html).first&.dig("data") || []
    data.is_a?(Hash) ? data.keys : data.map(&:first)
  end
end

RSpec.configure do |config|
  config.include ChartHelpers, type: :controller
end
