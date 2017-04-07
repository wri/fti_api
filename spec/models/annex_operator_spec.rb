# == Schema Information
#
# Table name: annex_operators
#
#  id         :integer          not null, primary key
#  country_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe AnnexOperator, type: :model do
  context 'Annex governance' do
    before :each do
      FactoryGirl.create(:annex_operator, illegality: 'Z Illegality')
      @annex = create(:annex_operator)
    end

    it 'Count on annex' do
      expect(AnnexOperator.count).to                eq(2)
      expect(AnnexOperator.all.first.illegality).to eq('Z Illegality')
      expect(@annex.country.name).to                match('Country')
      expect(@annex.illegality).to                  eq('Illegality one')
      expect(@annex.laws.first.legal_reference).to  eq('Lorem')
    end

    it 'Order by illegality asc' do
      expect(AnnexOperator.by_illegality_asc.first.illegality).to eq('Illegality one')
    end

    it 'Fallbacks for empty translations on annex' do
      I18n.locale = :fr
      expect(@annex.illegality).to eq('Illegality one')
      I18n.locale = :en
    end

    it 'Translate annex to fr' do
      @annex.update(illegality: 'Illegality one FR', locale: :fr)
      I18n.locale = :fr
      expect(@annex.illegality).to eq('Illegality one FR')
      I18n.locale = :en
      expect(@annex.illegality).to eq('Illegality one')
    end

    it 'Fetch all annex operators' do
      expect(AnnexOperator.fetch_all(nil).count).to eq(2)
    end

    it 'Illegality select' do
      expect(AnnexOperator.illegality_select(country_id: @annex.country_id).count).to eq(1)
    end
  end
end
