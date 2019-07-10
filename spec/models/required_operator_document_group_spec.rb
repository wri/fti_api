require 'rails_helper'

RSpec.describe RequiredOperatorDocumentGroup, type: :model do
  subject(:required_operator_document_group) { FactoryGirl.build :required_operator_document_group }

  it 'is valid with valid attributes' do
    expect(required_operator_document_group).to be_valid
  end

  it_should_behave_like 'translatable', FactoryGirl.create(:required_operator_document_group), %i[name]

  describe 'Relations' do
    it { is_expected.to have_many(:required_operator_documents).dependent(:destroy) }
    it { is_expected.to have_many(:required_operator_document_countries) }
    it { is_expected.to have_many(:required_operator_document_fmus) }
  end
end
