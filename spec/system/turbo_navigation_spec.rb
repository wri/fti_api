require "system_helper"

RSpec.describe "Admin: Turbo navigation", type: :system do
  let(:admin) { create(:admin) }

  let!(:country1) { create(:country) }
  let!(:country2) { create(:country) }
  let!(:observer1) { create(:observer, countries: [country1]) }
  let!(:observer2) { create(:observer, countries: [country2]) }

  before do
    sign_in admin
    visit "/admin/monitors"
  end

  def turbo_visit(path)
    page.execute_script("Turbo.visit(arguments[0])", path)
  end

  it "re-initializes page scripts after Turbo visits without a full reload" do
    expect(page).to have_css(".sidebar_toggle_btn", count: 1)
    select2_count = page.all(".filter_form .select2-container", visible: :all).count

    page.execute_script(<<~JS)
      window.turboMarker = true;
      window.jsErrors = [];
      window.addEventListener("error", (e) => window.jsErrors.push(e.message));
    JS

    turbo_visit("/admin/monitors/#{observer1.id}")
    expect(page).to have_current_path("/admin/monitors/#{observer1.id}")
    expect(page).to have_content(observer1.name)

    turbo_visit("/admin/monitors")
    expect(page).to have_current_path("/admin/monitors")
    expect(page).to have_css(".sidebar_toggle_btn", count: 1)
    expect(page.all(".filter_form .select2-container", visible: :all).count).to eq(select2_count)

    select2(country2.name, from: "Country")
    expect(select2_options(from: "Name")).to match_array([observer2.name])

    expect(page.evaluate_script("window.turboMarker")).to be(true)
    expect(page.evaluate_script("window.jsErrors")).to eq([])
  end

  it "initializes translation tabs and the quill editor after a Turbo visit" do
    turbo_visit("/admin/tools/new")

    expect(page).to have_current_path("/admin/tools/new")
    expect(page).to have_css(".activeadmin-translations .add-locale")
    expect(page).to have_css(".ql-toolbar", minimum: 1)
  end

  it "keeps form submissions as full page loads" do
    expect(page.evaluate_script("Turbo.config.forms.mode")).to eq("off")
  end
end
