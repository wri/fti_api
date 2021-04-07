# frozen_string_literal: true

class GlobalObservationScoreService
  def initialize(date = Date.today)
    @date = date
  end

  # Calculates the global observation scores based on the observations and reports
  def call
    calculate
  end

  private

  def calculate
    GlobalObservationScore.calculate(@date)
  end
end
