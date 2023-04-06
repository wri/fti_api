# frozen_string_literal: true

module ArrayForestTypeable
  extend ActiveSupport::Concern

  included do
    validate :validate_forest_types

    def validate_forest_types
      if !forest_types.is_a?(Array) || forest_types.detect { |d| !ForestType::TYPES.key?(d) }
        errors.add(:forest_types, :invalid)
      end
    end

    def forest_types
      super.map { |x| ForestType::TYPES.select { |_, h| h[:index] == x }.keys[0] }
    end

    def forest_types=(array)
      array.reject!(&:blank?)
      array.uniq!
      super
    end
  end
end
