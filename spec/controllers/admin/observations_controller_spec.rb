require 'rails_helper'

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::ObservationsController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  # maybe we should refactor all admin specs and remove common active_admin_spec.rb
  context 'gov observation' do
    let!(:observation) { create(:gov_observation) }

    before do
      create(:observation_document, observation: observation)
    end

    describe "GET index" do
      subject { get :index }

      it { is_expected.to be_successful }

      it 'responds to csv' do
        get :index, format: :csv
        expect(response.body).to be_present # otherwise it does not invoke csv code
        expect(response.content_type).to include('text/csv')
      end
    end

    describe "GET show" do
      subject { get :show, params: { id: observation.id }}

      it { is_expected.to be_successful }
    end

    describe "GET edit" do
      subject { get :edit, params: { id: observation.id }}

      it { is_expected.to be_successful }
    end
  end

  describe 'member actions' do
    describe 'PUT ready_for_publication' do
      let(:observation) { create(:observation, force_status: 'QC in progress') }

      before { put :ready_for_publication, params: {id: observation.id} }

      it 'is successful' do
        expect(flash[:notice]).to match('Observation moved to Ready for Publication')
        expect(observation.reload.validation_status).to eq('Ready for publication')
      end
    end

    describe 'PUT needs_revision' do
      let(:observation) { create(:observation, force_status: 'QC in progress') }

      before { put :needs_revision, params: {id: observation.id} }

      it 'is successful' do
        expect(flash[:notice]).to match('Observation moved to Needs Revision')
        expect(observation.reload.validation_status).to eq('Needs revision')
      end
    end

    describe 'PUT start_qc' do
      let(:observation) { create(:observation, force_status: 'Ready for QC') }

      before { put :start_qc, params: {id: observation.id} }

      it 'is successful' do
        expect(flash[:notice]).to match('Observation moved to QC in Progress')
        expect(observation.reload.validation_status).to eq('QC in progress')
      end
    end
  end

  describe 'batch actions' do
    describe 'move_to_qc_in_progress' do
      let(:observation1) { create(:observation, :with_translations, validation_status: 'Ready for QC') }
      let(:observation2) { create(:gov_observation, :with_translations, validation_status: 'Created') }
      let(:obs_ids) { [observation1.id, observation2.id] }

      before do
        post :batch_action,
          params: {
            batch_action: 'move_to_qc_in_progress',
            collection_selection: obs_ids
          }
      end

      it 'is successful' do
        expect(observation1.reload.validation_status).to eq('QC in progress')
        expect(observation2.reload.validation_status).to eq('Created') # only can change if it was Ready for QC
        expect(flash[:notice]).to match('QC started')
      end
    end

    describe 'move_to_needs_revision' do
      let(:observation1) { create(:observation, :with_translations, validation_status: 'QC in progress') }
      let(:observation2) { create(:gov_observation, :with_translations, validation_status: 'Created') }
      let(:obs_ids) { [observation1.id, observation2.id] }

      before do
        post :batch_action,
          params: {
            batch_action: 'move_to_needs_revision',
            collection_selection: obs_ids
          }
      end

      it 'is successful' do
        expect(observation1.reload.validation_status).to eq('Needs revision')
        expect(observation2.reload.validation_status).to eq('Created') # only can change if it was QC in progress
        expect(flash[:notice]).to match('Required revision for observations')
      end
    end

    describe 'move_to_ready_for_publication' do
      let(:observation1) { create(:observation, :with_translations, validation_status: 'QC in progress') }
      let(:observation2) { create(:gov_observation, :with_translations, validation_status: 'Created') }
      let(:obs_ids) { [observation1.id, observation2.id] }

      before do
        post :batch_action,
          params: {
            batch_action: 'move_to_ready_for_publication',
            collection_selection: obs_ids
          }
      end

      it 'is successful' do
        expect(observation1.reload.validation_status).to eq('Ready for publication')
        expect(observation2.reload.validation_status).to eq('Created') # only can change if it was QC in progress
        expect(flash[:notice]).to match('Observations ready to be published')
      end
    end

    describe 'hide' do
      let(:observation1) { create(:observation, :with_translations, validation_status: 'QC in progress', hidden: false) }
      let(:observation2) { create(:gov_observation, :with_translations, validation_status: 'Created', hidden: false) }
      let(:obs_ids) { [observation1.id, observation2.id] }

      before do
        post :batch_action,
          params: {
            batch_action: 'hide',
            collection_selection: obs_ids
          }
      end

      it 'is successful' do
        expect(observation1.reload.hidden).to eq(true)
        expect(observation2.reload.hidden).to eq(true)
        expect(flash[:notice]).to match('Documents hidden!')
      end
    end

    describe 'unhide' do
      let(:observation1) { create(:observation, :with_translations, validation_status: 'QC in progress', hidden: true) }
      let(:observation2) { create(:gov_observation, :with_translations, validation_status: 'Created', hidden: true) }
      let(:obs_ids) { [observation1.id, observation2.id] }

      before do
        post :batch_action,
          params: {
            batch_action: 'unhide',
            collection_selection: obs_ids
          }
      end

      it 'is successful' do
        expect(observation1.reload.hidden).to eq(false)
        expect(observation2.reload.hidden).to eq(false)
        expect(flash[:notice]).to match('Documents unhidden!')
      end
    end
  end
end
