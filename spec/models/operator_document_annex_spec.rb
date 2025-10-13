# == Schema Information
#
# Table name: operator_document_annexes
#
#  id          :integer          not null, primary key
#  name        :string
#  start_date  :date
#  expire_date :date
#  deleted_at  :date
#  status      :integer
#  attachment  :string
#  uploaded_by :integer
#  user_id     :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  public      :boolean          default(TRUE), not null
#

require "rails_helper"

RSpec.describe OperatorDocumentAnnex, type: :model do
  subject(:operator_document_annex) { FactoryBot.build(:operator_document_annex) }

  it "is valid with valid attributes" do
    expect(operator_document_annex).to be_valid
  end

  describe "Instance methods" do
    describe "#expire_document_annex" do
      it "set status to doc_expired" do
        operator_document_annex =
          create(:operator_document_annex, status: OperatorDocumentAnnex.statuses[:doc_pending])
        operator_document_annex.expire_document_annex

        expect(operator_document_annex.status).to eql "doc_expired"
      end
    end

    describe "#needs_authorization_before_downloading?" do
      let(:operator) { create(:operator) }
      let(:required_operator_document) { create(:required_operator_document_country, contract_signature: false) }
      let(:operator_document) { create(:operator_document_country, operator: operator, required_operator_document: required_operator_document, force_status: doc_status, public: is_public) }
      let(:operator_document_annex) { create(:operator_document_annex, operator_document: operator_document, force_status: annex_status) }
      let(:doc_status) { :doc_valid }
      let(:annex_status) { :doc_valid }
      let(:is_public) { true }

      context "when annex is valid" do
        let(:annex_status) { :doc_valid }

        context "when operator document does not need authorization" do
          let(:doc_status) { :doc_valid }
          let(:is_public) { true }

          before do
            allow(operator).to receive(:publication_authorization_signed?).and_return(true)
          end

          it "returns false" do
            expect(operator_document_annex.needs_authorization_before_downloading?).to be false
          end
        end

        context "when operator document needs authorization" do
          let(:doc_status) { :doc_valid }
          let(:is_public) { false }

          before do
            allow(operator).to receive(:publication_authorization_signed?).and_return(false)
          end

          it "returns true" do
            expect(operator_document_annex.needs_authorization_before_downloading?).to be true
          end
        end
      end

      context "when annex is expired" do
        let(:annex_status) { :doc_expired }

        context "when operator document does not need authorization" do
          let(:doc_status) { :doc_valid }
          let(:is_public) { true }

          before do
            allow(operator).to receive(:publication_authorization_signed?).and_return(true)
          end

          it "returns false" do
            expect(operator_document_annex.needs_authorization_before_downloading?).to be false
          end
        end

        context "when operator document needs authorization" do
          let(:doc_status) { :doc_valid }
          let(:is_public) { false }

          before do
            allow(operator).to receive(:publication_authorization_signed?).and_return(false)
          end

          it "returns true" do
            expect(operator_document_annex.needs_authorization_before_downloading?).to be true
          end
        end
      end

      context "when annex is not valid or expired" do
        let(:annex_status) { :doc_pending }

        it "returns true" do
          expect(operator_document_annex.needs_authorization_before_downloading?).to be true
        end
      end
    end
  end

  describe "Class methods" do
    describe "#expire_document_annexes" do
      before do
        FactoryBot.create_list :operator_document_annex, 3
      end

      it "set all operator_document_annex statuses to doc_expired" do
        OperatorDocumentAnnex.expire_document_annexes

        OperatorDocumentAnnex.where("expire_date IS NOT NULL and expire_date < '#{Time.zone.today}'::date and status = 3").find_each do |operator_document_annex|
          expect(operator_document_annex.status).to eql "doc_expired"
        end
      end
    end
  end
end
