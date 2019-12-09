require 'rails_helper'

RSpec.describe OperatorDocumentFmu, type: :model do
  subject(:operator_document_fmu) { FactoryBot.build :operator_document_fmu }

  it 'is valid with valid attributes' do
    expect(operator_document_fmu).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:required_operator_document_fmu)
      .with_foreign_key('required_operator_document_id')
      .required
    }
    it { is_expected.to belong_to(:fmu).required }
  end
end
