# == Schema Information
#
# Table name: annex_governances
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe AnnexGovernance, type: :model do
  context 'Annex governance' do
    before :each do
      FactoryGirl.create(:annex_governance, governance_problem: 'Z Annex governance problem')
      @annex = create(:annex_governance)
    end

    it 'Count on annex' do
      expect(AnnexGovernance.count).to                       eq(2)
      expect(AnnexGovernance.all.first.governance_problem).to eq('Z Annex governance problem')
    end

    it 'Order by governance_problem asc' do
      expect(AnnexGovernance.by_governance_problem_asc.first.governance_problem).to eq('Annex governance problem')
    end

    it 'Fallbacks for empty translations on annex' do
      I18n.locale = :fr
      expect(@annex.governance_problem).to eq('Annex governance problem')
      I18n.locale = :en
    end

    it 'Translate annex to fr' do
      @annex.update(governance_problem: 'Annex governance problem FR', locale: :fr)
      I18n.locale = :fr
      expect(@annex.governance_problem).to eq('Annex governance problem FR')
      I18n.locale = :en
      expect(@annex.governance_problem).to eq('Annex governance problem')
    end

    it 'Fetch all annex governances' do
      expect(AnnexGovernance.fetch_all(nil).count).to eq(2)
    end

    it 'Governance problem select' do
      expect(AnnexGovernance.governance_problem_select.count).to eq(2)
    end
  end
end
