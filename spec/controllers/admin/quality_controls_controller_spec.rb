require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::QualityControlsController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe "GET new" do
    let!(:observation) { create(:observation, validation_status: "QC2 in progress") }

    subject { get :new, params: {quality_control: {reviewable_id: observation.id, reviewable_type: "Observation"}} }

    it { is_expected.to be_successful }
  end

  describe "POST create" do
    let!(:observation) { create(:observation, validation_status: "QC2 in progress") }
    let(:valid_params) do
      {
        reviewable_id: observation.id,
        reviewable_type: "Observation",
        reviewer_id: admin.id,
        passed: false,
        comment: "Comment"
      }
    end
    let(:invalid_params) { valid_params.merge(comment: nil) }

    context "with valid params" do
      subject { post :create, params: {quality_control: valid_params} }

      it "creates a new Quality Control" do
        expect { subject }.to change(QualityControl, :count).by(1)
      end

      it "redirects to the reviewable" do
        expect(subject).to redirect_to(admin_observation_path(observation.id))
      end
    end

    context "with invalid params" do
      subject { post :create, params: {quality_control: invalid_params} }

      it "invalid_attributes do not create a new Quality Control" do
        expect { subject }.not_to change(QualityControl, :count)
      end
    end
  end
end
