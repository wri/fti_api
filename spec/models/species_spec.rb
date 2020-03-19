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
#  common_name     :string
#

require 'rails_helper'

RSpec.describe Species, type: :model do
  subject(:species) { FactoryBot.build(:species) }

  it 'is valid with valid attributes' do
    expect(species).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:species), %i[common_name]

  describe 'Relations' do
    it { is_expected.to have_many(:species_observations) }
    it { is_expected.to have_many(:species_countries) }
    it { is_expected.to have_many(:observations).through(:species_observations) }
    it { is_expected.to have_many(:countries).through(:species_countries) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'Instance methods' do
    describe '#cache_key' do
      it 'return the default value with the locale' do
        expect(species.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end

  describe 'Class methods' do
    describe '#fetch_all' do
      it 'returns all species' do
        expect(Species.fetch_all(nil).count).to eq(Species.all.size)
      end
    end
  end
end
