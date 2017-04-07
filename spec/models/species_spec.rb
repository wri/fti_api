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

require 'rails_helper'

RSpec.describe Species, type: :model do
  before :each do
    I18n.locale = :en
    FactoryGirl.create(:species, name: 'Z Species')
    @species = create(:species)
  end

  it 'Count on species' do
    expect(Species.count).to          eq(2)
    expect(Species.all.first.name).to eq('Z Species')
  end

  it 'Order by name asc' do
    expect(Species.by_name_asc.first.name).to eq('Spezie')
  end

  it 'Fallbacks for empty translations on species' do
    I18n.locale = :fr
    expect(@species.name).to eq('Spezie')
    I18n.locale = :en
  end

  it 'Translate species to fr' do
    @species.update(common_name: 'Species FR', locale: :fr)
    I18n.locale = :fr
    expect(@species.common_name).to eq('Species FR')
    I18n.locale = :en
    expect(@species.common_name).to eq('Species')
  end

  it 'Name validation' do
    @species = Species.new(name: '')

    @species.valid?
    expect { @species.save! }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Name can't be blank")
  end

  it 'Fetch all species' do
    expect(Species.fetch_all(nil).count).to eq(2)
  end
end
