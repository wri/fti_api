require "rails_helper"

RSpec.describe QualityControl, type: :model do
  subject(:quality_control) { build(:quality_control) }

  it { is_expected.to be_valid }

  it "should be invalid without a reviewable" do
    subject.reviewable = nil
    expect(subject).to have(1).error_on(:reviewable)
  end

  it "should be invalid without a reviewer" do
    subject.reviewer = nil
    expect(subject).to have(1).error_on(:reviewer)
  end

  it "should be invalid without passed" do
    subject.passed = nil
    expect(subject).to have(1).error_on(:passed)
  end

  it "should be invalid without a comment if not passed" do
    subject.passed = false
    expect(subject).to have(1).error_on(:comment)
  end

  describe "hooks" do
    let(:reviewable) { create(:observation, validation_status: "QC2 in progress") }
    subject(:quality_control) { build(:quality_control, reviewable: reviewable) }

    describe "on save" do
      it "should set the metadata" do
        expect(subject.metadata).to be_empty
        subject.save
        expect(subject.metadata).to_not be_empty
      end
    end

    describe "on create" do
      it "should update the reviewable qc status" do
        subject.save
        expect(reviewable.reload.validation_status).to eq("Ready for publication")
      end
    end
  end
end
