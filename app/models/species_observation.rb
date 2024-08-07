# frozen_string_literal: true

# == Schema Information
#
# Table name: species_observations
#
#  id             :integer          not null, primary key
#  observation_id :integer
#  species_id     :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#

class SpeciesObservation < ApplicationRecord
  belongs_to :observation
  belongs_to :species

  acts_as_paranoid
end
