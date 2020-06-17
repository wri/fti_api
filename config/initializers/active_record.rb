# frozen_string_literal: true

module ActiveRecord
  module QueryMethods
    def structurally_incompatible_values_for_or(other)
      Relation::SINGLE_VALUE_METHODS.reject { |m| send("#{m}_value") == other.send("#{m}_value") } +
          (Relation::MULTI_VALUE_METHODS - [:eager_load, :references, :extending]).reject { |m| send("#{m}_values") == other.send("#{m}_values") } +
          (Relation::CLAUSE_METHODS - [:having, :where]).reject { |m| send("#{m}_clause") == other.send("#{m}_clause") }
    end
  end
end
