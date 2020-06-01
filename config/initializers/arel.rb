# frozen_string_literal: true

module Arel
  class Nodes::ContainsArray < Arel::Nodes::Binary
    def operator
      :"@>"
    end
  end

  class Visitors::PostgreSQL
    private

    def visit_Arel_Nodes_ContainsArray(obj, collector)
      infix_value obj, collector, ' @> '
    end
  end

  module Predications
    def contains(other)
      Nodes::ContainsArray.new self, Nodes.build_quoted(other, self)
    end
  end
end
