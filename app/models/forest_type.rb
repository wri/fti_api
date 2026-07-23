class ForestType
  TYPES = {
    fmu: {index: 0, geojson_label: ""},
    ufa: {index: 1, geojson_label: "ufa"},
    cf: {index: 2, geojson_label: "communal"},
    vdc: {index: 3, geojson_label: "ventes_de_coupe"},
    cpaet: {index: 4, geojson_label: "CPAET"},
    cfad: {index: 5, geojson_label: "CFAD"},
    pea: {index: 6, geojson_label: "PEA"},
    cdc: {index: 7, geojson_label: "cdc"},
    ccf: {index: 8, geojson_label: "ccf"}
  }.with_indifferent_access.freeze
  TYPES_WITH_CODE = TYPES.map { |k, v| {k => v[:index]} }.reduce({}, :merge).with_indifferent_access

  def self.label(key)
    I18n.t(key, scope: :forest_types)
  end

  def self.select_collection
    TYPES.map { |k, h| [label(k), h[:index]] }
  end
end
