# == Schema Information
#
# Table name: global_observation_scores
#
#  id              :integer          not null, primary key
#  date            :date             not null
#  obs_total       :integer
#  rep_total       :integer
#  rep_country     :jsonb
#  rep_monitor     :jsonb
#  obs_country     :jsonb
#  obs_status      :jsonb
#  obs_producer    :jsonb
#  obs_severity    :jsonb
#  obs_category    :jsonb
#  obs_subcategory :jsonb
#  obs_fmu         :jsonb
#  obs_forest_type :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class GlobalObservationScore < ApplicationRecord
  validates_presence_of :date
  validates_uniqueness_of :date


end
