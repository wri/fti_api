require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::ObservationsController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  # maybe we should refactor all admin specs and remove common active_admin_spec.rb
  context "gov observation" do
    let!(:observation) { create(:gov_observation) }

    before do
      create(:observation_document, observations: [observation])
    end

    describe "GET index" do
      subject { get :index }

      it { is_expected.to be_successful }

      it "responds to csv" do
        get :index, format: :csv
        expect(response.body).to be_present # otherwise it does not invoke csv code
        expect(response.content_type).to include("text/csv")
      end
    end

    describe "GET show" do
      subject { get :show, params: {id: observation.id} }

      it { is_expected.to be_successful }
    end

    describe "GET edit" do
      subject { get :edit, params: {id: observation.id} }

      it { is_expected.to be_successful }
    end
  end

  describe "member actions" do
    describe "PUT start_qc" do
      let(:observation) { create(:observation, force_status: "Ready for QC2") }

      before { put :start_qc, params: {id: observation.id} }

      it "is successful" do
        expect(flash[:notice]).to match("Observation moved to QC in Progress")
        expect(observation.reload.validation_status).to eq("QC2 in progress")
        expect(response).to redirect_to(new_admin_quality_control_path(quality_control: {reviewable_id: observation.id, reviewable_type: "Observation"}))
      end
    end

    describe "PUT force_translations" do
      let(:observation) { create(:observation, :with_translations) }

      it "calls force_translations on the observation" do
        expect(TranslationJob).to receive(:perform_later)
        put :force_translations, params: {id: observation.id}
      end

      it "reloads the page" do
        put :force_translations, params: {id: observation.id}
        expect(response).to redirect_to(admin_observation_path(observation))
      end
    end
  end

  describe "batch actions" do
    describe "hide" do
      let(:observation1) { create(:observation, :with_translations, validation_status: "QC2 in progress", hidden: false) }
      let(:observation2) { create(:gov_observation, :with_translations, validation_status: "Created", hidden: false) }
      let(:obs_ids) { [observation1.id, observation2.id] }

      before do
        post :batch_action,
          params: {
            batch_action: "hide",
            collection_selection: obs_ids
          }
      end

      it "is successful" do
        expect(observation1.reload.hidden).to eq(true)
        expect(observation2.reload.hidden).to eq(true)
        expect(flash[:notice]).to match("Documents hidden!")
      end
    end

    describe "unhide" do
      let(:observation1) { create(:observation, :with_translations, validation_status: "QC2 in progress", hidden: true) }
      let(:observation2) { create(:gov_observation, :with_translations, validation_status: "Created", hidden: true) }
      let(:obs_ids) { [observation1.id, observation2.id] }

      before do
        post :batch_action,
          params: {
            batch_action: "unhide",
            collection_selection: obs_ids
          }
      end

      it "is successful" do
        expect(observation1.reload.hidden).to eq(false)
        expect(observation2.reload.hidden).to eq(false)
        expect(flash[:notice]).to match("Documents unhidden!")
      end
    end
  end
end
