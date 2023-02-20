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

RSpec.describe RequiredOperatorDocument, type: :model do
  subject(:required_operator_document) { FactoryBot.build(:required_operator_document) }

  it 'is valid with valid attributes' do
    expect(required_operator_document).to be_valid
  end

  it_should_behave_like 'translatable', :required_operator_document, %i[explanation]

  describe 'Validations' do
    it { is_expected.to validate_numericality_of(:valid_period).is_greater_than(0) }

    describe '#fixed_fields_unchanged' do
      context 'when it is persisted' do
        before do
          @required_operator_document = create(
            :required_operator_document,
            contract_signature: false,
            forest_types: [:fmu],
            type: 'RequiredOperatorDocument')
        end

        context 'when contract_signature has changed' do
          it 'add an error on contract_signature' do
            @required_operator_document.update(contract_signature: true)

            expect(@required_operator_document.valid?).to eql false
            expect(@required_operator_document.errors[:contract_signature]).to eql(
              ['Cannot change the contract signature']
            )
          end
        end

        context 'when forest_type has changed' do
          it 'add an error on forest_type' do
            @required_operator_document.update(forest_types: [0])

            expect(@required_operator_document.valid?).to eql false
            expect(@required_operator_document.errors[:forest_types]).to eql(
              ['Cannot change the forest type']
            )
          end
        end

        context 'when type has changed' do
          it 'add an error on type' do
            @required_operator_document.update(type: 'RequiredOperatorDocumentCountry')

            expect(@required_operator_document.valid?).to eql false
            expect(@required_operator_document.errors[:type]).to eql(
              ['Cannot change document type']
            )
          end
        end

        context 'when country_id has changed' do
          it 'add an error on country_id' do
            another_country = create(:country)
            @required_operator_document.update(country_id: another_country.id)

            expect(@required_operator_document.valid?).to eql false
            expect(@required_operator_document.errors[:country_id]).to eql(
              ['Cannot change the country']
            )
          end
        end
      end
    end
  end

  describe 'Hooks' do
    describe '#destroy' do
      before do
        country = create(:country)
        create(:operator, country: country, fa_id: 'fa_id')
        create(:operator, country: country, fa_id: 'fa_id')

        @required_operator_document = create(
          :required_operator_document_country,
          contract_signature: false,
          country: country
        )
      end

      it 'destroy operator_documents associated with the document' do
        expect(OperatorDocument.count).to eq(2) # for operator1 and operator2
        expect(OperatorDocument.deleted.count).to eq(0)

        @required_operator_document.destroy

        expect(OperatorDocument.deleted.count).to eq(2)
        expect(OperatorDocument.count).to eq(0)
      end
    end
  end
end
