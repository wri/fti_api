# == Schema Information
#
# Table name: laws
#
#  id                 :integer          not null, primary key
#  written_infraction :text
#  infraction         :text
#  sanctions          :text
#  min_fine           :integer
#  max_fine           :integer
#  penal_servitude    :string
#  other_penalties    :text
#  apv                :text
#  subcategory_id     :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  country_id         :integer
#  currency           :string
#

require 'rails_helper'

RSpec.describe Law, type: :model do
  subject(:law) { FactoryBot.build(:law) }

  it 'is valid with valid attributes' do
    expect(law).to be_valid
  end

  describe 'Validations' do
    describe '#min_fine' do
      context 'is present' do
        before { allow(subject).to receive(:min_fine?).and_return(true) }
        it { is_expected.to validate_numericality_of(:min_fine).is_greater_than_or_equal_to(0) }
      end
    end

    describe '#max_fine' do
      context 'is present' do
        before { allow(subject).to receive(:max_fine?).and_return(true) }
        it { is_expected.to validate_numericality_of(:max_fine).is_greater_than_or_equal_to(0) }
      end
    end
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:subcategory).inverse_of(:laws) }
    it { is_expected.to belong_to(:country).inverse_of(:laws) }
    it { is_expected.to have_many(:observations).inverse_of(:law) }
  end
end
