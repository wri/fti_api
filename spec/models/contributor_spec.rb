require 'rails_helper'

RSpec.describe Contributor, type: :model do
  subject(:contributor) { FactoryBot.build :contributor }

  it 'is valid with valid attributes' do
    expect(contributor).to be_valid
  end

  it_should_behave_like 'translatable', FactoryBot.create(:contributor), %i[name description]

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }

    describe '#priority' do
      context 'is priority' do
        before { allow(subject).to receive(:priority?).and_return(true) }
        it { is_expected.to validate_numericality_of(:priority).only_integer.is_greater_than_or_equal_to(0) }
      end
    end
  end
end
