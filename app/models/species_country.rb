# frozen_string_literal: true

# == Schema Information
#
# Table name: species_countries
#
#  id         :integer          not null, primary key
#  country_id :integer
#  species_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class SpeciesCountry < ApplicationRecord
  belongs_to :country
  belongs_to :species
end
