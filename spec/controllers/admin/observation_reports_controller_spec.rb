require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::ObservationReportsController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before { sign_in admin }

  describe "DELETE really_destroy" do
    let!(:observation_report) { create(:observation_report) }

    subject { delete :really_destroy, params: {id: observation_report.id} }

    context "when report not soft deleted" do
      before do
        expect { subject }.not_to change { ObservationReport.unscoped.count }
      end

      it "displays error message to move to recycle bin first" do
        expect(flash[:notice]).to match("Report must be moved to recycle bin first!")
      end
    end

    context "when report soft deleted" do
      before do
        observation_report.destroy!
        expect { subject }.to change { ObservationReport.unscoped.count }.by(-1)
      end

      it "is successful" do
        expect(flash[:notice]).to match("Report removed!")
      end
    end
  end
end
