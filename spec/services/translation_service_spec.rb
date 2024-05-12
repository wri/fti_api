require "rails_helper"

RSpec.describe TranslationService do
  let(:service) { described_class.new }

  describe "#call" do
    before do
      mock_service = double("Google::Cloud::Translate")
      allow(Google::Cloud::Translate).to receive(:translation_v2_service).and_return(mock_service)
    end

    it { expect(service).to respond_to(:call).with(3).arguments }
  end
end
