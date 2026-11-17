# frozen_string_literal: true

# FMU feature properties (map tiles, `fmus?format=geojson`, admin) computed from columns at read time.
# SQL expects `fmus` in FROM together with JOINS_SQL.
module FmuProperties
  CERTIFICATIONS = %w[fsc pefc olb pafc fsc_cw pbn tlv ls].freeze
  KEYS = (%w[id fmu_name iso3_fmu company_na operator_id forest_type fmu_type_label observations] +
    CERTIFICATIONS.map { |c| "certification_#{c}" }).freeze

  JOINS_SQL = <<~SQL.squish
    LEFT JOIN countries fmu_country ON fmu_country.id = fmus.country_id
    LEFT JOIN LATERAL (
      SELECT operators.id, operators.name
      FROM fmu_operators
      INNER JOIN operators ON operators.id = fmu_operators.operator_id
      WHERE fmu_operators.fmu_id = fmus.id AND fmu_operators.current AND fmu_operators.deleted_at IS NULL
      ORDER BY fmu_operators.id
      LIMIT 1
    ) fmu_current_operator ON TRUE
  SQL

  JSONB_SQL = <<~SQL.squish
    jsonb_build_object(
      'id', fmus.id,
      'fmu_name', fmus.name,
      'iso3_fmu', fmu_country.iso,
      'company_na', fmu_current_operator.name,
      'operator_id', fmu_current_operator.id,
      'forest_type', CASE fmus.forest_type #{ForestType::TYPES.map { |key, type| "WHEN #{type[:index]} THEN '#{key}'" }.join(" ")} END,
      'fmu_type_label', CASE fmus.forest_type #{ForestType::TYPES.map { |_key, type| "WHEN #{type[:index]} THEN '#{type[:geojson_label]}'" }.join(" ")} END,
      #{CERTIFICATIONS.map { |c| "'certification_#{c}', fmus.certification_#{c}" }.join(", ")},
      'observations', (
        SELECT count(*) FROM observations
        WHERE observations.fmu_id = fmus.id AND observations.is_active
          AND observations.hidden IS NOT TRUE AND observations.deleted_at IS NULL
      )
    )
  SQL

  def self.for(fmu_ids)
    return {} if fmu_ids.empty?

    sql = ActiveRecord::Base.sanitize_sql(["SELECT fmus.id, #{JSONB_SQL} FROM fmus #{JOINS_SQL} WHERE fmus.id IN (?)", fmu_ids])
    ActiveRecord::Base.connection.select_rows(sql).to_h { |id, properties| [id.to_i, JSON.parse(properties)] }
  end
end
