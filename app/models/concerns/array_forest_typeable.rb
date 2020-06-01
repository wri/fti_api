# frozen_string_literal: true

require 'active_support/concern'

module ArrayForestTypeable
  extend ActiveSupport::Concern
  include ConstForestTypes

  included do
    validate :validate_forest_types

    def validate_forest_types
      if !forest_types.is_a?(Array) || forest_types.detect{ |d| !FOREST_TYPES.key?(d) }
        errors.add(:forest_types, :invalid)
      end
    end

    def forest_types
      super.map{ |x| FOREST_TYPES.select{ |_,h| h[:index] == x }.keys[0] }
    end

    def forest_types=(array)
      array.reject!(&:blank?)
      array.uniq!
      super
    end
  end

  class_methods do
    FOREST_TYPES
  end
end
