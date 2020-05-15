# frozen_string_literal: true

module HashHelper
  def self.aggregate(array)
    result = {}
    array.each do |element|
      if result[element.keys.first].present?
        result[element.keys.first] << element.values.first unless result[element.keys.first].include?(element.values.first)
      else
        result[element.keys.first] = [element.values.first]
      end
    end
    result
  end
end
