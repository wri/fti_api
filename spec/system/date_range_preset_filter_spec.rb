require "system_helper"

RSpec.describe "Admin: Date range preset filter", type: :system do
  let(:admin) { create(:admin) }
  let(:decoded_url) { URI.decode_www_form_component(page.current_url) }

  before do
    sign_in admin
    visit "/admin/observations_dashboards"
  end

  it "shows the dates only for a custom range" do
    expect(page).to have_select("q_date_preset", selected: "Last 12 months")
    expect(page).to have_no_field("q_date_gteq")

    select "Custom", from: "q_date_preset"
    expect(page).to have_field("q_date_gteq")

    select "All time", from: "q_date_preset"
    expect(page).to have_no_field("q_date_gteq")
  end

  it "sends only the preset for all time" do
    select "All time", from: "q_date_preset"
    click_button "Filter"

    expect(page).to have_current_path(/q(%5B|\[)date_preset(%5D|\])=all_time/)
    expect(decoded_url).not_to include("q[date_gteq]")
    expect(page).to have_select("q_date_preset", selected: "All time")
  end

  it "sends the dates for a custom range" do
    select "Custom", from: "q_date_preset"
    fill_in "q_date_gteq", with: "2020-01-01"
    find("#q_date_gteq").send_keys(:escape) # close the datepicker covering the button
    click_button "Filter"

    expect(page).to have_current_path(/q(%5B|\[)date_preset(%5D|\])=custom/)
    expect(decoded_url).to include("q[date_gteq]=2020-01-01")
    expect(page).to have_field("q_date_gteq", with: "2020-01-01")
  end
end
