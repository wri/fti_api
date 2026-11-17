require "rails_helper"

RSpec.describe FmuProperties do
  let(:country) { create(:country, iso: "CMR") }
  let(:operator) { create(:operator, country: country, fa_id: "fa_id", name: "Timber Co") }
  let!(:fmu) { create(:fmu_geojson, country: country, forest_type: :cf, certification_fsc: true) }

  def properties = described_class.for([fmu.id])[fmu.id]

  it "computes every property from columns" do
    create(:fmu_operator, fmu: fmu, operator: operator)

    expect(properties).to eq(
      "id" => fmu.id,
      "fmu_name" => fmu.name,
      "iso3_fmu" => "CMR",
      "company_na" => "Timber Co",
      "operator_id" => operator.id,
      "forest_type" => "cf",
      "fmu_type_label" => "communal",
      "certification_fsc" => true,
      "certification_pefc" => false,
      "certification_olb" => false,
      "certification_pafc" => false,
      "certification_fsc_cw" => false,
      "certification_pbn" => false,
      "certification_tlv" => false,
      "certification_ls" => false,
      "observations" => 0
    )
    expect(fmu.properties).to eq(properties)
  end

  it "counts only active, non-hidden, non-deleted observations" do
    create(:observation, operator: operator, fmu: fmu)
    create(:observation, operator: operator, fmu: fmu, validation_status: "Created")
    create(:observation, operator: operator, fmu: fmu, hidden: true)
    create(:observation, operator: operator, fmu: fmu).destroy!

    expect(properties["observations"]).to eq(1)
  end

  it "drops the operator once the allocation is deactivated" do
    create(:fmu_operator, fmu: fmu, operator: operator, start_date: 10.days.ago, end_date: 2.days.from_now)
    expect(properties["company_na"]).to eq("Timber Co")

    travel_to 5.days.from_now do
      FmuOperator.calculate_current
      expect(properties.values_at("company_na", "operator_id")).to eq([nil, nil])
    end
  end

  it "returns one row per fmu even with two current allocations" do
    create(:fmu_operator, fmu: fmu, operator: operator)
    create(:fmu_operator, fmu: fmu, operator: create(:operator, country: country), current: false, start_date: 5.days.ago, end_date: 2.days.ago)
      .update_column(:current, true)

    rows = ActiveRecord::Base.connection.select_value(
      ActiveRecord::Base.sanitize_sql(["SELECT count(*) FROM fmus #{FmuProperties::JOINS_SQL} WHERE fmus.id = ?", fmu.id])
    )
    expect(rows).to eq(1)
  end

  it "returns an empty hash for no ids" do
    expect(described_class.for([])).to eq({})
  end
end
