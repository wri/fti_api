class ForestType
  TYPES = {
    fmu: { index: 0, label: 'FMU', geojson_label: '' },
    ufa: { index: 1, label: 'UFA', geojson_label: 'ufa' },
    cf: { index: 2, label: 'Communal Forest', geojson_label: 'communal' },
    vdc: { index: 3, label: 'Vente de Coupe', geojson_label: 'ventes_de_coupe' },
    cpaet: { index: 4, label: 'CPAET', geojson_label: 'CPAET' },
    cfad: { index: 5, label: 'CFAD', geojson_label: 'CFAD' },
    pea: { index: 6, label: 'PEA', geojson_label: 'PEA' }
  }.with_indifferent_access.freeze
  TYPES_WITH_CODE = TYPES.map { |k, v| { k => v[:index] } }.reduce({}, :merge).with_indifferent_access

  def self.select_collection
    TYPES.map { |k, h| [h[:label], h[:index]] }
  end
end
