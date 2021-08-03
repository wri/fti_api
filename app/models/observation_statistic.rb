# == Schema Information
#
# Table name: observation_statistics
#
#  id                :integer          not null, primary key
#  date              :date             not null
#  country_id        :integer
#  operator_id       :integer
#  subcategory_id    :integer
#  category_id       :integer
#  fmu_id            :integer
#  severity_level    :integer
#  validation_status :integer
#  fmu_forest_type   :integer
#  total_count       :integer          default("0")
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# This model wont have any data in DB, sql query will provide data for active admin dashboard
class ObservationStatistic < ApplicationRecord
  belongs_to :country, optional: true
  belongs_to :fmu, optional: true
  belongs_to :category, optional: true
  belongs_to :subcategory, optional: true
  belongs_to :operator, optional: true

  enum validation_status: { "Created" => 0, "Ready for QC" => 1, "QC in progress" => 2, "Approved" => 3,
                           "Rejected" => 4, "Needs revision" => 5, "Ready for publication" => 6,
                           "Published (no comments)" => 7, "Published (not modified)" => 8,
                           "Published (modified)" => 9 }

  validates_presence_of :date

  # just to hack around active admin
  def self.ransackable_scopes(auth_object = nil)
    [:by_country]
  end

  # just to hack around active admin, does not have to filter by country
  def self.by_country(country_id = nil)
    all
  end

  def country_name
    return country.name if country.present?

    'All Countries'
  end
end
