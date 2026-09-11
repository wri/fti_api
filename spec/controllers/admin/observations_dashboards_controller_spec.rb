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

  describe "GET index with all countries filter" do
    before { get :index, params: {q: {by_country: "null"}} }

    it "keeps the option selected and shows it in current filters" do
      doc = response.parsed_body
      expect(doc.css("#q_by_country option[selected]").pluck("value")).to eq(["null"])
      current_filters = doc.css("#search_status_sidebar_section li").map { |li| li.text.squish }
      expect(current_filters).to include("Country equals All Countries")
    end
  end

  describe "GET index with more rows than a page" do
    before { get :index, params: {per_page: 1} }

    it "pages the table but charts all dates" do
      all_countries_dates = ObservationStatistic.query_dashboard_report(date_gteq: 1.year.ago)
        .select { |r| r.country_id.nil? }.map { |r| r.date.to_date.to_s }.uniq

      expect(all_countries_dates.size).to be > 1
      expect(response.parsed_body.css(".index_table tbody tr").size).to eq(1)
      expect(chart_dates(response.body)).to match_array(all_countries_dates)
    end
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
