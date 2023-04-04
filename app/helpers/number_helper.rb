# frozen_string_literal: true

# TODO: Rails 5.2.3 already has ActionView::Helpers::NumberHelper.number_to_percentage
# When updating rails, this should be removed
module NumberHelper
  def self.float_to_percentage(number)
    (number * 100).to_i.to_s + "%"
  end
end
