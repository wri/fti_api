# == Schema Information
#
# Table name: governments
#
#  id                :integer          not null, primary key
#  country_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  is_active         :boolean          default("true")
#  government_entity :string
#  details           :text
#

require 'rails_helper'

RSpec.describe Government, type: :model do
  subject(:government) { FactoryBot.build(:government) }

  it 'is valid with valid attributes' do
    expect(government).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:government), %i[details]

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:government_entity) }
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:country).inverse_of(:governments).optional }
    it { is_expected.to have_many(:governments_observations).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:observations).through(:governments_observations) }
  end

  describe 'Instance methods' do
    describe '#cache_key' do
      it 'return the default value with the locale' do
        expect(government.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end

  describe 'Class methods' do
    describe '#fetch_all' do
      before do
        @country = create(:country)
        create(:government, country: @country)
        create(:government)
      end

      context 'when country_ids is not specified' do
        it 'fetch all operators' do
          expect(Government.fetch_all(nil).count).to eq(Government.all.size)
        end
      end

      context 'when country is specified' do
        it 'fetch operators filtered by country' do
          expect(Government.fetch_all({'country' => [@country.id]}).to_a).to eql(
            Government.where(country_id: @country.id).includes(:country).to_a
          )
        end
      end
    end
  end
end
