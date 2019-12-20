require 'rails_helper'

RSpec.describe OperatorDocumentCountry, type: :model do
  subject(:operator_document_country) { FactoryBot.build(:operator_document_country) }

  it 'is valid with valid attributes' do
    expect(operator_document_country).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:required_operator_document_country)
      .with_foreign_key('required_operator_document_id')
    }
  end

  describe 'Validations' do
    describe '#invalidate_operator' do
      context 'when operator is approved' do
        it 'set approved field to false on the operator' do
          operator = create(:operator, approved: true)
          required_operator_document =
            create(:required_operator_document, contract_signature: true)
          create(:operator_document_country,
                 required_operator_document: required_operator_document,
                 operator: operator)

          operator.reload
          expect(operator.approved).to eql false
        end
      end
    end

    describe '#validate_operator' do
      context 'when operator is not approved' do
        it 'set approved field to true on the operator' do
          operator = create(:operator, approved: false)
          required_operator_document =
            create(:required_operator_document, contract_signature: true)
          operator_document_country = create(
            :operator_document_country,
            required_operator_document: required_operator_document,
            operator: operator)

          operator_document_country.destroy

          operator.reload
          expect(operator.approved).to eql true
        end
      end
    end
  end

  describe 'Instance methods' do
    describe '#update_operator_approved' do
      context 'when there are current documents of contract signature not valid or required' do
        it 'set operator as non approved' do
          operator = create(:operator, approved: false)
          required_operator_document =
            create(:required_operator_document, contract_signature: true)
          operator_document_country = create(
            :operator_document_country,
            required_operator_document: required_operator_document,
            operator: operator)
          operator_document_country.send('update_operator_approved')

          operator.reload
          expect(operator.operator_id).to eql operator.id.to_s
          expect(operator.approved).to eql true
        end
      end
    end
  end
end
