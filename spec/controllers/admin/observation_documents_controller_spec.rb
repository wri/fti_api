require 'rails_helper'

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::EvidencesController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe 'DELETE really_destroy' do
    let!(:observation_document) { create(:observation_document) }

    subject { delete :really_destroy, params: {id: observation_document.id} }

    context 'when document not soft deleted' do
      before do
        expect { subject }.not_to change { ObservationDocument.unscoped.count }
      end

      it 'displays error message to move to recycle bin first' do
        expect(flash[:notice]).to match('Evidence must be moved to recycle bin first!')
      end
    end

    context 'when document soft deleted' do
      before do
        observation_document.destroy!
        expect { subject }.to change { ObservationDocument.unscoped.count }.by(-1)
      end

      it 'is successful' do
        expect(flash[:notice]).to match('Evidence removed!')
      end
    end
  end
end
