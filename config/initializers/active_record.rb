# frozen_string_literal: true

module ActiveRecord
  module QueryMethods
    def structurally_incompatible_values_for_or(other)
      Relation::SINGLE_VALUE_METHODS.reject { |m| send("#{m}_value") == other.send("#{m}_value") } +
        (Relation::MULTI_VALUE_METHODS - [:eager_load, :references, :extending]).reject { |m| send("#{m}_values") == other.send("#{m}_values") } +
        (Relation::CLAUSE_METHODS - [:having, :where]).reject { |m| send("#{m}_clause") == other.send("#{m}_clause") }
    end
  end

  # After upgrading to ransack 4.0 we need to explicitly whitelist attributes
  # In this project I prefer to only blacklist the attributes that are not allowed for couple models
  class Base
    def self.ransackable_attributes(auth_object = nil)
      @ransackable_attributes ||= authorizable_ransackable_attributes
    end

    def self.ransackable_associations(auth_object = nil)
      @ransackable_associations ||= authorizable_ransackable_associations
    end
  end
end
