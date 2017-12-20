# frozen_string_literal: true

module ValidationHelper

  # Returns true if it gets a list of ids divided by commas
  def self.ids?(ids)
    ids === /(\d)+(,(\d)+)*$/
  end
end
