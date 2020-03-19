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
#  forest_type                         :integer
#  contract_signature                  :boolean          default("false"), not null
#  required_operator_document_id       :integer          not null
#  explanation                         :text
#

require 'rails_helper'

RSpec.describe RequiredOperatorDocumentFmu, type: :model do
  subject(:required_operator_document_fmu) { FactoryBot.build(:required_operator_document_fmu) }

  it 'is valid with valid attributes' do
    expect(required_operator_document_fmu).to be_valid
  end

  it_should_behave_like 'forest_typeable', RequiredOperatorDocumentFmu

  describe 'Relations' do
    it { is_expected.to have_many(:operator_document_fmus).with_foreign_key('required_operator_document_id') }
  end

  describe 'Validations' do
    it { is_expected.to validate_absence_of(:contract_signature) }
  end

  describe 'Hooks' do
    describe '#create_operator_document_fmus' do
      before do
        @country = create(:country)
        3.times do
          operator = create(:operator, country: @country)
          fmu = create(:fmu, country: @country)
          create(:fmu_operator, fmu: fmu, operator: operator)
        end

        @required_operator_document_group = create(:required_operator_document_group)
      end


      it 'create or update status of operator_document_fmu to be doc_not_provided' do
        expect(RequiredOperatorDocumentFmu.all.size).to eql 0

        create(:required_operator_document_fmu,
          forest_type: nil,
          country: @country,
          required_operator_document_group: @required_operator_document_group)

        expect(OperatorDocumentFmu.all.size).to eql 3
      end
    end
  end
end
