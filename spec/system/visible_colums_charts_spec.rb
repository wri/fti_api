require "system_helper"

RSpec.describe "Admin: Visible Columns and Charts", type: :system do
  let(:admin) { create(:admin) }

  before do
    country1 = create(:country, name: "Poland")
    country2 = create(:country, name: "Germany")
    operator1 = create(:operator, fa_id: "FA1", country: country1)
    operator2 = create(:operator, fa_id: "FA2", country: country2)

    travel_to 2.days.ago do
      create(:operator_document_country, operator: operator1, force_status: "doc_valid")
      create(:operator_document_country, operator: operator1)
      create(:operator_document_country, operator: operator2, force_status: "doc_valid")
      create(:operator_document_country, operator: operator2)
    end

    travel_to 1.day.ago do
      create(:operator_document_country, operator: operator1, force_status: "doc_valid")
    end

    [2.days.ago, Date.yesterday, Date.today].each do |date|
      # nil represents all countries
      [country1.id, country2.id, nil].each do |country_id|
        OperatorDocumentStatistic.generate_for_country_and_day(country_id, date)
      end
    end
  end

  before do
    sign_in admin
    visit "/admin/producer_documents_dashboards"
  end

  it "should sync columns and chart visibility" do
    sleep 1 # wait for chart to be rendered
    # toggle valid visible column and see if column disappear/appear in table and on the chart
    # expect input checkbox to be checked
    expect(page).to have_checked_field("valid")
    expect(page).to have_selector("th.col-valid", visible: true)
    expect(get_legend_item("Valid")["hidden"]).to eq(false)
    page.uncheck("valid")
    expect(page).not_to have_checked_field("valid")
    expect(page).not_to have_selector("th.col-valid", visible: true)
    expect(get_legend_item("Valid")["hidden"]).to eq(true)
    # toggle valid in chart legend and see if column disappear/appear in table and on the chart and checkbox is changed as well
    legend_item_valid_hitbox = get_legend_item_hitbox("Valid")
    chart_x = page.evaluate_script("document.getElementById('chart-1').getBoundingClientRect().x")
    chart_y = page.evaluate_script("document.getElementById('chart-1').getBoundingClientRect().y")
    legend_item_valid_x = chart_x + legend_item_valid_hitbox["left"] + 10
    legend_item_valid_y = chart_y + legend_item_valid_hitbox["top"] + 3
    page.driver.click(legend_item_valid_x, legend_item_valid_y)
    expect(page).to have_checked_field("valid")
    expect(page).to have_selector("th.col-valid", visible: true)
    expect(get_legend_item("Valid")["hidden"]).to eq(false)
    # once there was something wrong after clicking on the legend item, so test clicking on checkbox again
    page.uncheck("valid")
    expect(page).not_to have_checked_field("valid")
    expect(page).not_to have_selector("th.col-valid", visible: true)
    expect(get_legend_item("Valid")["hidden"]).to eq(true)
  end

  it "should save columns visibility in local storage" do
    sleep 1 # wait for chart to be rendered
    # expect input checkbox to be checked
    expect(page).to have_checked_field("valid")
    expect(page).to have_selector("th.col-valid", visible: true)
    page.uncheck("valid")
    expect(page).not_to have_checked_field("valid")
    expect(page).not_to have_selector("th.col-valid", visible: true)
    # reload page
    page.evaluate_script("window.location.reload()")
    sleep 1 # wait for chart to be rendered
    # expect checkbox to still be unchecked
    expect(page).not_to have_checked_field("valid")
    expect(page).not_to have_selector("th.col-valid", visible: true)
  end

  def get_legend_item(name)
    page.evaluate_script("Chartkick.charts['chart-1'].chart.legend.legendItems.find(x => x.text === '#{name}')")
  end

  def get_legend_item_hitbox(name)
    legend_item = get_legend_item(name)
    page.evaluate_script("Chartkick.charts['chart-1'].chart.legend.legendHitBoxes[#{legend_item["datasetIndex"]}]")
  end
end
