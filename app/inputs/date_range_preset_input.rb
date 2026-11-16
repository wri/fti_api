# frozen_string_literal: true

# Date range filter with a preset select, the date inputs are shown only for the custom preset.
# DateRangePreset in the controller turns the preset into the date conditions.
class DateRangePresetInput < DateRangeInput
  def to_html
    input_wrapping do
      template.safe_join([
        label_html,
        template.select_tag(preset_input_name, template.options_for_select(preset_options, current_preset),
          id: "q_#{method}_preset", class: "date-range-preset"),
        template.content_tag(:span, class: "date-range-preset-custom", hidden: current_preset != DateRangePreset::CUSTOM) do
          template.safe_join([
            builder.text_field(gt_input_name, input_html_options_for(gt_input_name, gt_input_placeholder)),
            builder.text_field(lt_input_name, input_html_options_for(lt_input_name, lt_input_placeholder))
          ], "\n")
        end
      ], "\n")
    end
  end

  # keeps the date range filter styles
  def wrapper_html_options
    options = super
    options.merge(class: [options[:class], "filter_date_range"].compact.join(" "))
  end

  private

  def preset_input_name
    "q[#{method}_preset]"
  end

  def current_preset
    template.params.dig(:q, "#{method}_preset")
  end

  def preset_options
    DateRangePreset::PRESETS.map { |preset| [I18n.t("active_admin.filters.date_presets.#{preset}"), preset] }
  end
end
