# frozen_string_literal: true

module Ransack
  module Nodes
    class Value < Node
      alias_method :original_cast, :cast

      def cast(type)
        return Array(value) if type == :array

        original_cast(type)
      end
    end
  end
end

Ransack.configure do |config|
  config.add_predicate 'contains_array',
                       arel_predicate: 'contains',
                       formatter: proc { |v| "{#{v.join(',')}}" },
                       validator: proc { |v| v.present? },
                       type: :array
end
