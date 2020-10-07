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
#  attachment                    :string
#  current                       :boolean
#  deleted_at                    :datetime
#  uploaded_by                   :integer
#  user_id                       :integer
#  reason                        :text
#  note                          :text
#  response_date                 :datetime
#  public                        :boolean          default("true"), not null
#  source                        :integer          default("1")
#  source_info                   :string
#

require 'rails_helper'

RSpec.describe OperatorDocumentCountry, type: :model do
  subject(:operator_document_country) { FactoryBot.build(:operator_document_country) }

  it 'is valid with valid attributes' do
    expect(operator_document_country).to be_valid
  end

  describe 'Validations' do
    describe '#invalidate_operator' do
      context 'when operator is approved' do
        it 'set approved field to false on the operator' do
          country = create(:country)
          operator = create(:operator, approved: true, country: country)
          required_operator_document =
            create(:required_operator_document_country, contract_signature: true, country: country)
          operator_document = create(:operator_document_country,
                 required_operator_document: required_operator_document,
                 operator: operator, current: true)

          operator_document.status = :doc_valid
          operator_document.save
          expect(operator_document.status).to eql('doc_valid')
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

          operator_document_country.update_attributes(status: :doc_valid)

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

          operator_document_country.update_attributes(status: :doc_valid)
          operator_document_country.send('update_operator_approved')

          operator.reload

          expect(operator.operator_id).to eql("#{operator.country.iso}-unknown-#{operator.id}")
          expect(operator.approved).to eql true
        end
      end
    end
  end
end
