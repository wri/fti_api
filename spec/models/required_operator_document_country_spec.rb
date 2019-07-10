require 'rails_helper'

RSpec.describe RequiredOperatorDocumentCountry, type: :model do
  subject(:required_operator_document_country) { FactoryGirl.build :required_operator_document_country }

  it 'is valid with valid attributes' do
    expect(required_operator_document_country).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to have_many(:operator_document_countries).with_foreign_key('required_operator_document_id') }
  end

  describe 'Validations' do
    describe '#contract_signature' do
      context 'is a contract signature' do
        before { allow(subject).to receive(:contract_signature?).and_return(true) }
        it { is_expected.to validate_uniqueness_of(:contract_signature).scoped_to(:country_id) }
      end

      context 'is not a contract signature' do
        before { allow(subject).to receive(:contract_signature?).and_return(false) }
        it { is_expected.not_to validate_uniqueness_of(:contract_signature).scoped_to(:country_id) }
      end
    end
  end

  describe 'Hooks' do
    describe '#create_operator_document_countries' do
      before do
        @country = FactoryGirl.create(:country)
        FactoryGirl.create_list :operator, 3, country: @country

        @required_operator_document_group = FactoryGirl.create(:required_operator_document_group)
      end


      it 'create or update status of operator_document_country to be doc_not_provided' do
        expect(RequiredOperatorDocumentCountry.all.size).to eql 0

        FactoryGirl.create :required_operator_document_country,
          country: @country,
          required_operator_document_group: @required_operator_document_group

        expect(OperatorDocumentCountry.all.size).to eql 3
      end
    end
  end
end
