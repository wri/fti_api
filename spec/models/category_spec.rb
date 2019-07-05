# == Schema Information
#
# Table name: categories
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  category_type :integer
#

require 'rails_helper'

RSpec.describe Category, type: :model do
  before :each do
    FactoryGirl.create(:category, name: 'Z Category')
    @category = create(:category, name: '00 Category')
  end

  it_should_behave_like 'translatable', FactoryGirl.create(:category), %i[name]

  describe 'Relations' do
    it { is_expected.to have_many(:subcategories).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe 'Methods' do
    context '#cache_key' do
      it 'return the default value with the locale' do
        expect(@category.cache_key).to match(/-#{Globalize.locale.to_s}\z/)
      end
    end
  end

  describe 'Scopes' do
    context '#by_name_asc' do
      it 'Order by name asc' do
        expect(Category.by_name_asc.first.name).to eq('00 Category')
      end
    end
  end
end
