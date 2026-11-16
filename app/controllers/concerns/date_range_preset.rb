# frozen_string_literal: true

# Turns the date range preset filter (see DateRangePresetInput) into ransack date conditions.
# Dates given without a preset, e.g. from a link, count as a custom range.
module DateRangePreset
  LAST_YEAR = "last_year"
  ALL_TIME = "all_time"
  CUSTOM = "custom"
  PRESETS = [LAST_YEAR, ALL_TIME, CUSTOM].freeze

  private

  def apply_date_range_preset(attribute, default:)
    params[:q] ||= {}
    q = params[:q]
    preset_key = "#{attribute}_preset"
    gteq = "#{attribute}_gteq"
    lteq = "#{attribute}_lteq"

    preset = q[preset_key].presence_in(PRESETS) || ((q[gteq].present? || q[lteq].present?) ? CUSTOM : default)
    q[preset_key] = preset

    case preset
    when LAST_YEAR
      q[gteq] = 1.year.ago.to_date
      q.delete(lteq)
    when ALL_TIME
      q.delete(gteq)
      q.delete(lteq)
    end
  end
end
