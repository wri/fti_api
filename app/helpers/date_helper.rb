module DateHelper

  # Returns true if two date ranges intersect
  # It assumes that both dates have a start date and
  # at least one has an end date.
  # It takes two arrays with a start and end date
  def intersects?(date1, date2)
    !((date1[1].present? && date1[0] < date2[0] && date1[1] < date2[0]) ||
        (date2[1].present? && date2[0] < date1[0] && date2[1] < date1[0]))
  end
end