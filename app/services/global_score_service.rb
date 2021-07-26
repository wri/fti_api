# frozen_string_literal: true

class GlobalScoreService
  def initialize; end

  # Calculates the global scores based on the documents
  def call
    Country.active.find_each { |country| calculate(country) }
    # [1.month.ago..Date.today].each do |day|
    # end

    calculate
  end

  private

  def calculate(country = nil)
    GlobalScore.calculate(country)
  end
end
