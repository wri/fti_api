# == Schema Information
#
# Table name: countries
#
#  id                         :integer          not null, primary key
#  iso                        :string
#  region_iso                 :string
#  country_centroid           :jsonb
#  region_centroid            :jsonb
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  is_active                  :boolean          default(FALSE), not null
#  percentage_valid_documents :float
#

require 'rails_helper'

RSpec.describe Country, type: :model do
  subject(:country) { FactoryBot.build :country }

  it 'is valid with valid attributes' do
    country = FactoryBot.build :country
    expect(country).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:country), %i[name region_name]

  context 'Relations' do
    it { is_expected.to have_many(:users).inverse_of(:country) }
    it { is_expected.to have_many(:observations).inverse_of(:country) }
    it { is_expected.to have_and_belong_to_many(:observers) }
    it { is_expected.to have_many(:governments).inverse_of(:country) }
    it { is_expected.to have_many(:operators).inverse_of(:country) }
    it { is_expected.to have_many(:fmus).inverse_of(:country) }
    it { is_expected.to have_many(:laws) }
    it { is_expected.to have_many(:species_countries) }
    it { is_expected.to have_many(:species).through(:species_countries) }
    it { is_expected.to have_many(:required_operator_documents) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  context 'Hooks' do
    describe '#set_active' do
      context 'when is_active has not been initialized' do
        it 'set is_active to true' do
          country = FactoryBot.create(:country, is_active: nil)
          expect(country.is_active).to eql true
        end
      end

      context 'when is_active has been intialized' do
        it 'keep the value of is_active' do
          country = Country.create(is_active: false)
          expect(country.is_active).to eql false
        end
      end
    end
  end

  context 'Methods' do
    describe '#cache_key' do
      it 'return the default value with the locale' do
        country = FactoryBot.create :country
        expect(country.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end
end
