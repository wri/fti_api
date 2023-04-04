# frozen_string_literal: true

module Privateable
  extend ActiveSupport::Concern

  class_methods do
    # Facilitates hiding a list of methods based on a condition
    # It grabs a list of attributes and creates a method for each
    # that will display the attribute if the validation_attr is true
    # otherwise it displays nil
    # @param [Boolean] validation_attr The attribute used to assert that the other attributes will be shown. When true the attribute is displayed.
    # @param [Array] attrs_list the list of attributes
    def privateable(validation_attr, attrs_list)
      attrs_list.each do |attr|
        define_method(attr) do
          return nil unless public_send(validation_attr.to_s)

          instance_variable_get(:@model).public_send(attr)
        end
      end
    end
  end
end
