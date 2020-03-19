# == Schema Information
#
# Table name: operator_document_annexes
#
#  id                   :integer          not null, primary key
#  operator_document_id :integer
#  name                 :string
#  start_date           :date
#  expire_date          :date
#  deleted_at           :date
#  status               :integer
#  attachment           :string
#  uploaded_by          :integer
#  user_id              :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  public               :boolean          default("true"), not null
#

require 'rails_helper'

RSpec.describe OperatorDocumentAnnex, type: :model do
  subject(:operator_document_annex) { FactoryBot.build(:operator_document_annex) }

  it 'is valid with valid attributes' do
    expect(operator_document_annex).to be_valid
  end

  describe 'Relations' do
    it { is_expected.to belong_to(:operator_document).required }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:operator_document_id) }
    it { is_expected.to validate_presence_of(:start_date) }
    # Existing before_validation for the status
    #it { is_expected.to validate_presence_of(:status) }
  end

  describe 'Enums' do
    it { is_expected.to define_enum_for(:status).with_values(
      { doc_pending: 1, doc_invalid: 2, doc_valid: 3, doc_expired: 4 }
    ) }
    it { is_expected.to define_enum_for(:uploaded_by).with_values(
      { operator: 1, monitor: 2, admin: 3, other: 4 }
    ) }
  end

  describe 'Instance methods' do
    describe '#expire_document_annex' do
      it 'set status to doc_expired' do
        operator_document_annex =
          create(:operator_document_annex, status: OperatorDocumentAnnex.statuses[:doc_pending])
        operator_document_annex.expire_document_annex

        expect(operator_document_annex.status).to eql 'doc_expired'
      end
    end
  end

  describe 'Class methods' do
    describe '#expire_document_annexes' do
      before do
        FactoryBot.create_list :operator_document_annex, 3
      end

      it 'set all operator_document_annex statuses to doc_expired' do
        OperatorDocumentAnnex.expire_document_annexes

        OperatorDocumentAnnex.where("expire_date IS NOT NULL and expire_date < '#{Date.today}'::date and status = 3").each do |operator_document_annex|
          expect(operator_document_annex.status).to eql 'doc_expired'
        end
      end
    end
  end
end
