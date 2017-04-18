# frozen_string_literal: true

# == Schema Information
#
# Table name: species
#
#  id              :integer          not null, primary key
#  name            :string
#  species_class   :string
#  sub_species     :string
#  species_family  :string
#  species_kingdom :string
#  scientific_name :string
#  cites_status    :string
#  cites_id        :integer
#  iucn_status     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class SpeciesSerializer < ActiveModel::Serializer
  attributes :id, :common_name, :name, :species_class, :sub_species,
             :species_family, :species_kingdom, :scientific_name,
             :cites_status, :cites_id, :iucn_status

  has_many :countries, serializer: CountrySerializer
end
