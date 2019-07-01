require 'active_support/concern'

module ForestTypeable
  extend ActiveSupport::Concern

  included do
    enum forest_type: FOREST_TYPES.map {|x| {x.first => x.last[:index]}}.reduce({}, :merge)
  end

  class_methods do
    FOREST_TYPES = {
        fmu:     { index: 0, label: 'FMU' },
        ufa:     { index: 1, label: 'UFA' },
        cf:      { index: 2, label: 'Communal Forest' },
        vdc:     { index: 3, label: 'Vente de Coupe'}
    }
  end
end