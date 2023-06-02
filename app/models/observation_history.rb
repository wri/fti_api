# frozen_string_literal: true

# == Schema Information
#
# Table name: observation_histories
#
#  id                     :integer          not null, primary key
#  validation_status      :integer
#  observation_type       :integer
#  evidence_type          :integer
#  location_accuracy      :integer
#  severity_level         :integer
#  fmu_forest_type        :integer
#  observation_updated_at :datetime
#  observation_created_at :datetime
#  deleted_at             :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  observation_id         :integer
#  fmu_id                 :integer
#  category_id            :integer
#  subcategory_id         :integer
#  country_id             :integer
#  operator_id            :integer
#  hidden                 :boolean          default(FALSE), not null
#  is_active              :boolean          default(FALSE), not null
#
class ObservationHistory < ApplicationRecord
  acts_as_paranoid

  enum observation_type: {"operator" => 0, "government" => 1}
  enum validation_status: {"Created" => 0, "Ready for QC" => 1, "QC in progress" => 2, "Approved" => 3,
                           "Rejected" => 4, "Needs revision" => 5, "Ready for publication" => 6,
                           "Published (no comments)" => 7, "Published (not modified)" => 8,
                           "Published (modified)" => 9}
  enum evidence_type: {"Government Documents" => 0, "Company Documents" => 1, "Photos" => 2,
                       "Testimony from local communities" => 3, "Other" => 4, "Evidence presented in the report" => 5,
                       "Maps" => 6}
  enum location_accuracy: {"Estimated location" => 0, "GPS coordinates extracted from photo" => 1,
                           "Accurate GPS coordinates" => 2}
  enum fmu_forest_type: ForestType::TYPES_WITH_CODE

  belongs_to :observation
  belongs_to :country
  belongs_to :operator, optional: true
  belongs_to :fmu, optional: true

  belongs_to :subcategory, optional: true
  belongs_to :category, optional: true
end
