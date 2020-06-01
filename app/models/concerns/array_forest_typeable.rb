# frozen_string_literal: true

require 'active_support/concern'

module ArrayForestTypeable
  extend ActiveSupport::Concern
  include ConstForestTypes

  included do
    def forest_types
      super.map{ |x| FOREST_TYPES.select{ |_,h| h[:index] == x }.keys[0] }
    end

    def forest_types=(array)
      array.each do |a|
        raise ArgumentError.new('Forest types can only be integers') unless a.is_a?(Integer)
        raise ArgumentError.new('Forest types must be in the list') unless (FOREST_TYPES.values.map{ |x| x[:index] }).include?(a)
      end
      super
    end
  end

  class_methods do
    FOREST_TYPES
  end
end
