# == Schema Information
#
# Table name: sawmills
#
#  id          :integer          not null, primary key
#  name        :string
#  lat         :float
#  lng         :float
#  is_active   :boolean          default(TRUE), not null
#  operator_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  geojson     :jsonb
#

require 'rails_helper'

RSpec.describe Sawmill, type: :model do
  subject(:sawmill) { FactoryBot.build(:sawmill) }

  it 'is valid with valid attributes' do
    expect(sawmill).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:operator) }
  end

  describe 'Validations' do
    it { is_expected.to validate_numericality_of(:lat)
      .is_greater_than_or_equal_to(-90)
      .is_less_than_or_equal_to(90)
    }
    it { is_expected.to validate_numericality_of(:lng)
      .is_greater_than_or_equal_to(-180)
      .is_less_than_or_equal_to(180)
    }
  end

  describe 'Hooks' do
    describe '#update_geojson' do
      it 'update geojson data' do
        sawmill = create(:sawmill)

        sawmill.reload
        expect(sawmill.geojson).to eql({
          'id' => sawmill.id,
          'type' => 'Feature',
          'geometry' => {
            'type' => 'Point',
            # ST_AsGeoJSON: we use value 9 for maxdecimaldigits argument.
            'coordinates' => [sawmill.lng.round(9), sawmill.lat.round(9)]
          },
          'properties' => {
            'name' => sawmill.name,
            'is_active' => sawmill.is_active,
            'operator_id' => sawmill.operator_id
          }
        })
      end
    end
  end

  describe 'Class methods' do
    describe '#fetch_all' do
      before :all do
        @operator = create(:operator)
        another_operator = create(:operator)

        create(:sawmill, operator: @operator, is_active: false)
        create(:sawmill, operator: another_operator, is_active: true)
        create(:sawmill, operator: @operator, is_active: true)
      end

      context 'when operator_ids and active are not specified' do
        it 'fetch all sawmills' do
          expect(Sawmill.fetch_all(nil).count).to eq(Sawmill.all.size)
        end
      end

      context 'when operator_ids is specified' do
        it 'fetch sawmills filtered by operators' do
          expect(Sawmill.fetch_all({'operator_ids' => @operator.id.to_s}).to_a).to eql(
            Sawmill.includes(:operator).where(operator_id: @operator.id).to_a
          )
        end
      end

      context 'when active is specified' do
        it 'fetch sawmills filtered by active' do
          expect(Sawmill.fetch_all({'active' => true}).to_a).to eql(
            Sawmill.includes(:operator).where(is_active: true).to_a
          )
        end
      end
    end
  end
end
