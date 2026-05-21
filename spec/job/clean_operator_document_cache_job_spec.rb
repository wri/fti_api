require "rails_helper"

RSpec.describe CleanOperatorDocumentCacheJob, type: :job do
  describe "#perform" do
    let(:operator) { create(:operator) }

    context "when the operator has documents and histories" do
      before do
        allow(Operator).to receive(:find_by).with(id: operator.id).and_return(operator)
        allow(operator).to receive(:operator_document_ids).and_return([10, 11])
        allow(operator).to receive(:operator_document_history_ids).and_return([20, 21])
      end

      it "invalidates cached document and history fragments" do
        expect(Rails.cache).to receive(:delete_matched)
          .with(/operator_documents\/(10|11)\//).ordered
        expect(Rails.cache).to receive(:delete_matched)
          .with(/operator_document_histories\/(20|21)\//).ordered

        described_class.perform_now(operator.id)
      end
    end
  end
end
