require "rails_helper"

RSpec.describe FmuGeometry, type: :model, versioning: true do
  let(:moved_geojson) do
    {
      "type" => "Feature",
      "geometry" => {"type" => "Polygon", "coordinates" => [[[10.0, 0.0], [11.0, 0.0], [11.0, 1.0], [10.0, 1.0], [10.0, 0.0]]]},
      "properties" => {}
    }
  end

  let!(:fmu) { create(:fmu, :geojson_no_props) }
  let(:fmu_geometry) { fmu.reload.fmu_geometry }

  it "stores the geometry computed from the geojson" do
    expect(fmu_geometry.geometry).to be_present
    expect(fmu.geometry.coordinates).to eq(fmu.geojson.dig("geometry", "coordinates"))
  end

  it "versions geojson changes without the geometry column" do
    original = fmu_geometry.geojson

    fmu.geojson = moved_geojson
    fmu.save!

    versions = fmu_geometry.versions.order(:id)
    expect(versions.map(&:event)).to eq(%w[create update])
    expect(versions.last.object["geojson"]).to eq(original)
    expect(versions.last.object_changes["geojson"].last).to eq(moved_geojson)
    expect(versions.map(&:object).compact + versions.map(&:object_changes)).to all(satisfy { |h| !h.key?("geometry") })
    expect(fmu.versions.flat_map { |v| [v.object, v.object_changes] }.compact).to all(satisfy { |h| !h.key?("geojson") })
  end

  it "touches the fmu when only the geometry changes" do
    fmu.update_column(:updated_at, 1.day.ago)

    fmu.reload.geojson = moved_geojson
    fmu.save!

    expect(fmu.reload.updated_at).to be > 1.minute.ago
  end

  it "does not version geojson properties refreshes" do
    expect { fmu.update_geojson_properties }.not_to change { fmu_geometry.versions.count }
    expect(fmu_geometry.reload.properties["fmu_name"]).to eq(fmu.name)
  end

  it "keeps the geometry of a soft-deleted fmu" do
    fmu.destroy!

    expect(Fmu.with_deleted.find(fmu.id).geojson).to be_present
  end

  it "does not create a geometry for an fmu without geojson" do
    expect(create(:fmu, geojson: nil).reload.fmu_geometry).to be_nil
  end
end
