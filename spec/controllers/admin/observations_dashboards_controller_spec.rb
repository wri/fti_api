require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::ObservationsDashboardsController, type: :controller do
  let(:admin) { create(:admin) }

  before(:all) do
    travel_to 3.days.ago do
      create_list(:observation, 2)
    end
    travel_to 1.day.ago do
      create_list(:observation, 2)
    end
  end

  render_views

  before { sign_in admin }

  describe "GET index" do
    subject { get :index }

    it { is_expected.to be_successful }
  end

  describe "GET index with .csv format" do
    before do
      get :index, format: "csv"
    end

    it("returns CSV file") do
      expect(response).to have_http_status(:success)
      expect(response.header["Content-Type"]).to include("text/csv")
    end
  end
end
