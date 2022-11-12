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
#  forest_types                        :integer          default("{}"), is an Array
#  contract_signature                  :boolean          default("false"), not null
#  required_operator_document_id       :integer          not null
#  explanation                         :text
#  deleted_at                          :datetime
#

require 'rails_helper'

RSpec.describe RequiredOperatorDocumentCountry, type: :model do
  subject(:required_operator_document_country) { FactoryBot.build(:required_operator_document_country) }

  it 'is valid with valid attributes' do
    expect(required_operator_document_country).to be_valid
  end

  describe 'Hooks' do
    describe '#create_operator_document_countries' do
      before do
        @country = create(:country)
        create_list(:operator, 3, country: @country, fa_id: 'fa_id')

        @required_operator_document_group = create(:required_operator_document_group)
      end


      it 'create or update status of operator_document_country to be doc_not_provided' do
        expect(RequiredOperatorDocumentCountry.all.size).to eql 0

        create(:required_operator_document_country,
          country: @country,
          required_operator_document_group: @required_operator_document_group)

        expect(OperatorDocumentCountry.all.size).to eql 3
      end
    end
  end
end
