# == Schema Information
#
# Table name: global_scores
#
#  id               :integer          not null, primary key
#  date             :datetime         not null
#  total_required   :integer
#  general_status   :jsonb
#  country_status   :jsonb
#  fmu_status       :jsonb
#  doc_group_status :jsonb
#  fmu_type_status  :jsonb
#  country_id       :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class GlobalScore < ApplicationRecord
  belongs_to :country, optional: true
  validates_presence_of :date
  validates_uniqueness_of :date, scope: :country_id
end
