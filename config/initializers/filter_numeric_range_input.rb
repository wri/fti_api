# frozen_string_literal: true

module ActiveAdmin
  module Inputs
    class NumericRangeInput < ::Formtastic::Inputs::StringInput
      include Filters::Base

      # rubocop:disable Rails/OutputSafety
      def to_html
        input_wrapping do
          [label_html,
            builder.text_field(gt_input_name, input_html_options(gt_input_name)),
            template.content_tag(:span, "-", class: "separator"),
            builder.text_field(lt_input_name, input_html_options(lt_input_name))].join("\n").html_safe
        end
      end
      # rubocop:enable Rails/OutputSafety

      def gt_input_name
        "#{method}_gteq"
      end
      # alias :input_name :gt_input_name

      def lt_input_name
        "#{method}_lteq"
      end

      def input_html_options(input_name = gt_input_name)
        current_value = @object.send(input_name)
        {size: 10, id: "#{input_name}_numeric", value: current_value}
      end
    end
  end
end
