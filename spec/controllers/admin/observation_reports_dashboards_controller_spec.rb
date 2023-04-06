require "rails_helper"

# Base specs for admin default actions are done in active_admin_spec.rb
RSpec.describe Admin::ObservationReportsDashboardsController, type: :controller do
  let(:admin) { create(:admin) }

  render_views

  before(:all) do
    travel_to 3.days.ago do
      report1 = create(:observation_report)
      report2 = create(:observation_report)

      create_list(:observation, 2, observation_report: report1)
      create_list(:observation, 2, observation_report: report2)
    end

    travel_to 2.days.ago do
      report3 = create(:observation_report)
      create_list(:observation, 2, observation_report: report3)
    end

    Country.find_each do |country|
      ObservationReportStatistic.generate_for_country_and_day(country.id, 3.days.ago.to_date, true)
      ObservationReportStatistic.generate_for_country_and_day(country.id, 2.days.ago.to_date, true)
    end
  end

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
