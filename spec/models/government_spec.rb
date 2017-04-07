# == Schema Information
#
# Table name: governments
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Government, type: :model do
  before :each do
    FactoryGirl.create(:government, government_entity: 'Z Government')
    @government = create(:government)
  end

  it 'Count on government' do
    expect(Government.count).to          eq(2)
    expect(Government.all.first.government_entity).to eq('Z Government')
    expect(@government.country.name).to               match('Country')
  end

  it 'Order by government_entity asc' do
    expect(Government.by_entity_asc.first.government_entity).to eq('A Government')
  end

  it 'Fallbacks for empty translations on government' do
    I18n.locale = :fr
    expect(@government.government_entity).to eq('A Government')
    I18n.locale = :en
  end

  it 'Translate government to fr' do
    @government.update(government_entity: 'A Government FR', locale: :fr)
    I18n.locale = :fr
    expect(@government.government_entity).to eq('A Government FR')
    I18n.locale = :en
    expect(@government.government_entity).to eq('A Government')
  end

  it 'Fetch all governments' do
    expect(Government.fetch_all(nil).count).to eq(2)
  end

  it 'Governnment select for country' do
    expect(Government.entity_select(country_id: @government.country_id).size).to eq(1)
  end
end
