# == Schema Information
#
# Table name: required_operator_documents
#
#  id                                  :integer          not null, primary key
#  type                                :string
#  required_operator_document_group_id :integer
#  name                                :string
#  country_id                          :integer
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#  valid_period                        :integer
#  deleted_at                          :datetime
#  forest_types                        :integer          default([]), is an Array
#  contract_signature                  :boolean          default(FALSE), not null
#  position                            :integer
#  explanation                         :text
#  deleted_at                          :datetime
#

require 'rails_helper'

RSpec.describe RequiredOperatorDocumentFmu, type: :model do
  subject(:required_operator_document_fmu) { FactoryBot.build(:required_operator_document_fmu) }

  it 'is valid with valid attributes' do
    expect(required_operator_document_fmu).to be_valid
  end

  describe 'Validations' do
    it { is_expected.to validate_absence_of(:contract_signature) }
  end

  describe 'Hooks' do
    describe '#create_operator_document_fmus' do
      let(:operator_country) { create :country }
      let(:document_country) { operator_country }
      let(:fa_id) { 'FA_ID' }
      let(:operator) { create :operator, country: operator_country, fa_id: fa_id }
      let(:fmu) { create :fmu, country: operator_country }
      let!(:fmu_operator) { create :fmu_operator, fmu: fmu, operator: operator }
      let(:rod) { create :required_operator_document_fmu, country: document_country, forest_types: (1..6).to_a }

      subject { rod.save }

      it { expect{subject}.to change{OperatorDocument.count}.from(0).to(1) }
      it { expect{subject}.to change{OperatorDocument.first&.status}.from(NilClass).to('doc_not_provided') }

      context "when the operator country is not the same as the document's country" do
        let(:document_country) { create :country }

        it { expect{subject}.to_not change{OperatorDocument.count} }
      end

      context 'when the operator does not have an FA_ID' do
        let(:fa_id) { nil }

        it { expect{subject}.to_not change{OperatorDocument.count} }
      end
    end
  end
end
