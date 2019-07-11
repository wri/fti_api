require 'rails_helper'

RSpec.describe Faq, type: :model do
  subject(:faq) { FactoryGirl.build :faq }

  it 'is valid with valid attributes' do
    expect(faq).to be_valid
  end

  it_should_behave_like 'translatable', FactoryGirl.create(:faq), %i[question answer]

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:position) }

    it { is_expected.to validate_uniqueness_of(:position) }
  end
end
