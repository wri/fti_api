# == Schema Information
#
# Table name: observer_observations
#
#  id             :integer          not null, primary key
#  observer_id    :integer
#  observation_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ObserverObservation < ApplicationRecord
  belongs_to :observer, touch: true
  belongs_to :observation, touch: true
end
