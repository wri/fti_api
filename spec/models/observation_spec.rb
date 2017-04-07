# == Schema Information
#
# Table name: observations
#
#  id                  :integer          not null, primary key
#  annex_operator_id   :integer
#  annex_governance_id :integer
#  severity_id         :integer
#  observation_type    :string           not null
#  user_id             :integer
#  publication_date    :datetime
#  country_id          :integer
#  observer_id         :integer
#  operator_id         :integer
#  government_id       :integer
#  pv                  :string
#  is_active           :boolean          default(TRUE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'rails_helper'

RSpec.describe Observation, type: :model do
  context 'Observation count and filters' do
    before :each do
      I18n.locale    = :en
      @observation_g = create(:observation_2, publication_date: (DateTime.now - 1.days))
      @observation   = create(:observation_1, publication_date: DateTime.now)
    end

    it 'Count on observation' do
      expect(Observation.count).to eq(2)
      expect(Observation.all.first
                        .publication_date.to_date).to    eq((DateTime.now - 1.days).to_date)
      expect(@observation.country.name).to               match('Country')
      expect(@observation.illegality).to                 eq('Illegality one')
      expect(@observation.laws.first.legal_reference).to eq('Lorem')
    end

    it 'Order by illegality desc' do
      expect(Observation.by_date_desc.first.publication_date.to_date).to eq(DateTime.now.to_date)
    end

    it 'Fallbacks for empty translations on observation' do
      I18n.locale = :fr
      expect(@observation.evidence).to eq('Operator observation')
      I18n.locale = :en
    end

    it 'Translate observation to fr' do
      @observation.update(evidence: 'Lorem ipsum.. FR', locale: :fr)
      I18n.locale = :fr
      expect(@observation.evidence).to eq('Lorem ipsum.. FR')
      I18n.locale = :en
      expect(@observation.evidence).to eq('Operator observation')
    end

    it 'Check methods' do
      expect(Observation.types).to             eq(['AnnexGovernance','AnnexOperator'])
      expect(Observation.translated_types).to  eq([["Governance illegality", "AnnexGovernance"], ["Illegality", "AnnexOperator"]])
      expect(@observation_g.is_governance?).to eq(true)
      expect(@observation.is_operator?).to     eq(true)
      expect(@observation.title).to            eq('Illegality one')
      expect(@observation_g.title).to          eq('Annex governance problem')
      expect(@observation.user_name).to        eq('Admin user')
      expect(@observation.translated_type).to  eq('Illegality')
    end
  end
end
