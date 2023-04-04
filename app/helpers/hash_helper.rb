# frozen_string_literal: true

module HashHelper
  # example
  # array = [['a', 1], ['a', 2], ['b', 3], ['b', 4]]
  # HashHelper.aggregate(array)
  # => {"a"=>[1, 2], "b"=>[3, 4]}
  def self.aggregate(array)
    array.group_by(&:first).transform_values { |v| v.map(&:last) }.delete_if { |k, _v| k.nil? }
  end
end
