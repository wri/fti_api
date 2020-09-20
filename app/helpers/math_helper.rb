module MathHelper

  # Divides the number of results of 2 queries
  # @param [ActiveRecord::Relation] numerator The numerator query
  # @param [ActiveRecord::Relation] denominator The denominator query
  # @return [Float] the number of records in numerator over the number of records in denominator.
  # When there are nils or the denominator is zero, the result is 0
  def query_divider(numerator, denominator)
    return 0 if denominator.count.zero?

    numerator.count.to_f / denominator.count.to_f
  rescue
    0
  end
end