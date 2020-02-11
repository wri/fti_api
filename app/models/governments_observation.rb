# frozen_string_literal: true

# == Schema Information
#
# Table name: governments_observations
#
#  id             :integer          not null, primary key
#  government_id  :integer
#  observation_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class GovernmentsObservation < ApplicationRecord
  belongs_to :observation
  belongs_to :government
end
