require "system_helper"

RSpec.describe "Admin: Filter Saver", type: :system do
  let(:admin) { create(:admin) }

  let!(:country1) { create(:country) }
  let!(:country2) { create(:country) }
  let!(:observer1) { create(:observer, countries: [country1]) }
  let!(:observer2) { create(:observer, countries: [country1]) }
  let!(:observer3) { create(:observer, countries: [country2]) }

  before do
    sign_in admin
    visit "/admin/monitors"
  end

  it "saves selected filters" do
    # match observers from country 2
    select2(country2.name, from: "Country")
    click_button "Filter"
    # expect table index_table_monitor to have observer3
    expect(page).to have_content("Current filters")
    expect(page).to have_css("table#index_table_monitors", text: observer3.name)
    expect(page).not_to have_css("table#index_table_monitors", text: observer1.name)
    expect(page).not_to have_css("table#index_table_monitors", text: observer2.name)

    visit "/admin/producers" # visit another page to change context
    expect(page).not_to have_content("Current filters")
    visit "/admin/monitors"
    # after visiting another page, the filter should still be applied
    expect(page).to have_content("Current filters")
    expect(page).to have_css("table#index_table_monitors", text: observer3.name)
    expect(page).not_to have_css("table#index_table_monitors", text: observer1.name)
    expect(page).not_to have_css("table#index_table_monitors", text: observer2.name)
  end
end
