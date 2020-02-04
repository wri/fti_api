require 'rails_helper'

RSpec.describe Subcategory, type: :model do
  subject(:subcategory) { FactoryBot.build(:subcategory) }

  it 'is valid with valid attributes' do
    expect(subcategory).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:subcategory), %i[name details]

  describe 'Enums' do
    it { is_expected.to define_enum_for(:subcategory_type).with_values(
      { operator: 0, government: 1 }
    ) }
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:category) }
    it { is_expected.to have_many(:severities).dependent(:destroy) }
    it { is_expected.to have_many(:observations).inverse_of(:subcategory).dependent(:destroy) }
    it { is_expected.to have_many(:laws).inverse_of(:subcategory) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:subcategory_type) }
  end
end
