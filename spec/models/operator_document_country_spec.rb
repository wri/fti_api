# == Schema Information
#
# Table name: operator_documents
#
#  id                            :integer          not null, primary key
#  type                          :string
#  expire_date                   :date
#  start_date                    :date
#  fmu_id                        :integer
#  required_operator_document_id :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  status                        :integer
#  operator_id                   :integer
#  deleted_at                    :datetime
#  uploaded_by                   :integer
#  user_id                       :integer
#  reason                        :text
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean          default(TRUE), not null
#  source                        :integer          default("company")
#  source_info                   :string
#  document_file_id              :integer
#

require 'rails_helper'

RSpec.describe OperatorDocumentCountry, type: :model do
  subject(:operator_document_country) { FactoryBot.build(:operator_document_country) }

  it 'is valid with valid attributes' do
    expect(operator_document_country).to be_valid
  end

  describe 'Validations' do
    describe '#invalidate_operator' do
      context 'when operator was approved' do
        it 'set approved field to false on the operator' do
          country = create(:country)
          operator = create(:operator, approved: true, country: country, fa_id: 'fa_id')
          # below should already create not_provided signature document which should invalidate approved status of operator
          required_operator_document = create(:required_operator_document_country, contract_signature: true, country: country)
          operator.reload
          expect(operator.approved).to eql false
        end
      end
    end

    describe '#validate_operator' do
      context 'when operator was not approved' do
        it 'set approved field to true on the operator' do
          operator = create(:operator, approved: false)
          required_operator_document =
            create(:required_operator_document, contract_signature: true)
          operator_document_country = create(
            :operator_document_country,
            required_operator_document: required_operator_document,
            operator: operator)
          operator_document_country.update!(status: :doc_valid)
          operator.reload
          expect(operator.approved).to eql true
        end
      end
    end
  end
end
