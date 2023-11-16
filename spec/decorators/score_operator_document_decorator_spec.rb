require "rails_helper"

RSpec.describe ScoreOperatorDocumentDecorator do
  before :all do
    travel_to 2.days.ago do
      country = create(:country)
      @operator = create(:operator, country: country, fa_id: "FA_ID")
      create_list(:required_operator_document_country, 3, country: country)
    end

    @operator.operator_documents.first.update!(status: "doc_valid", document_file: create(:document_file), start_date: Time.zone.today)
    @operator.operator_documents.second.update!(status: "doc_pending", reason: "reason")
  end

  let(:scores) { ScoreOperatorDocument.where(operator_id: @operator.id).order(:date) }
  let(:last_score) { scores[-1] }
  let(:prev_score) { scores[-2] }

  subject { ScoreOperatorDocumentDecorator.new(last_score) }

  describe "#private_summary_diff" do
    it "shows valid private diff" do
      expect(subject.private_summary_diff(prev_score)).to match_snapshot("decorators/sod_decorator_private_diff", format: :text)
    end
  end

  describe "#public_summary_diff" do
    it "shows valid public diff" do
      expect(subject.public_summary_diff(prev_score)).to match_snapshot("decorators/sod_decorator_public_diff", format: :text)
    end
  end
end
