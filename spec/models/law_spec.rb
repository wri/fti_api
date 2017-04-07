# == Schema Information
#
# Table name: laws
#
#  id            :integer          not null, primary key
#  country_id    :integer
#  vpa_indicator :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'rails_helper'

RSpec.describe Law, type: :model do
  before :each do
    FactoryGirl.create(:law, legal_reference: 'Z Lorem')
    @law = create(:law)
  end

  it 'Count on law' do
    expect(Law.count).to                     eq(2)
    expect(Law.all.first.legal_reference).to eq('Z Lorem')
    expect(@law.country.name).to             match('Country')
  end

  it 'Order by legal_reference asc' do
    expect(Law.by_legal_reference_asc.first.legal_reference).to eq('Lorem')
  end

  it 'Fallbacks for empty translations on law' do
    I18n.locale = :fr
    expect(@law.legal_reference).to eq('Lorem')
    I18n.locale = :en
  end

  it 'Translate law to fr' do
    @law.update(legal_reference: 'Lorem FR', locale: :fr)
    I18n.locale = :fr
    expect(@law.legal_reference).to eq('Lorem FR')
    I18n.locale = :en
    expect(@law.legal_reference).to eq('Lorem')
  end

  it 'Fetch all laws' do
    expect(Law.fetch_all(nil).count).to eq(2)
  end
end
