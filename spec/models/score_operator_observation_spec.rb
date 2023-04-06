# == Schema Information
#
# Table name: score_operator_observations
#
#  id            :integer          not null, primary key
#  date          :date             not null
#  current       :boolean          default(TRUE), not null
#  score         :float
#  obs_per_visit :float
#  operator_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require "rails_helper"

RSpec.describe ScoreOperatorObservation, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
