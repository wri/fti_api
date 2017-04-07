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
#

class SpeciesObservation < ApplicationRecord
  belongs_to :observations
  belongs_to :species
end
