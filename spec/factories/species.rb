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

FactoryGirl.define do
  factory :species do
    common_name 'Species'
    name        'Spezie'
  end
end
