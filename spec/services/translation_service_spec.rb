require "rails_helper"

RSpec.describe TranslationService do
  let(:service) { described_class.new }

  describe "#call" do
    it { expect(service).to respond_to(:call).with(3).arguments }
  end
end
