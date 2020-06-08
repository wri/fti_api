# frozen_string_literal: true

require 'active_support/concern'

module ForestTypeable
  extend ActiveSupport::Concern
  include ConstForestTypes

  included do
    enum forest_type: FOREST_TYPES.map { |x| { x.first => x.last[:index] } }.reduce({}, :merge)
  end

  class_methods do
    FOREST_TYPES
  end
end
