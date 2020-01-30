# frozen_string_literal: true

require 'active_support/concern'

module ForestTypeable
  extend ActiveSupport::Concern

  included do
    enum forest_type: FOREST_TYPES.map {|x| { x.first => x.last[:index] }}.reduce({}, :merge)
  end

  class_methods do
    FOREST_TYPES = {
        fmu:     { index: 0, label: 'FMU', geojson_label: '' },
        ufa:     { index: 1, label: 'UFA', geojson_label: 'ufa' },
        cf:      { index: 2, label: 'Communal Forest', geojson_label: 'communal' },
        vdc:     { index: 3, label: 'Vente de Coupe', geojson_label: 'ventes_de_coupe' },
        cpaet:   { index: 4, label: 'CPAET', geojson_label: 'CPAET' },
        cfad:    { index: 5, label: 'CFAD', geojson_label: 'CFAD' },
        pea:     { index: 6, label: 'PEA', geojson_label: 'PEA' }
    }
  end
end
