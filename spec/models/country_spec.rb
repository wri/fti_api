# == Schema Information
#
# Table name: countries
#
#  id               :integer          not null, primary key
#  iso              :string
#  region_iso       :string
#  country_centroid :jsonb
#  region_centroid  :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  is_active        :boolean          default(FALSE), not null
#

require 'rails_helper'

RSpec.describe Country, type: :model do
  context 'For user relations' do
    before :each do
      @country = create(:country)
      @user    = create(:user, country: @country)
    end

    it 'Count on country' do
      expect(User.count).to          eq(1)
      expect(@country.users.size).to eq(1)
      expect(@user.country.name).to  match('Country')
    end

    it 'Fallbacks for empty translations on country' do
      expect(@user.country.name).to match('Country')
    end

    it 'Translate country to fr' do
      @country.update(name: 'Australia FR', locale: :fr)
      I18n.locale = :fr
      expect(@user.country.name).to eq('Australia FR')
      I18n.locale = :en
      expect(@user.country.name).to match('Country')
    end

    it 'Fetch all countries' do
      expect(Country.fetch_all(nil).count).to eq(1)
    end

    it 'Select for active countries' do
      expect(Country.active_country_select.count).to eq(1)
    end
  end
end
