require "rails_helper"

RSpec.describe CombinedVersion, versioning: true do
  let(:moved_geojson) do
    {
      "type" => "Feature",
      "geometry" => {"type" => "Polygon", "coordinates" => [[[10.0, 0.0], [11.0, 0.0], [11.0, 1.0], [10.0, 1.0], [10.0, 0.0]]]},
      "properties" => {}
    }
  end

  let!(:fmu) { create(:fmu, :geojson_no_props, name: "Old name") }
  let!(:original_geometry) { fmu.reload.geojson["geometry"] }

  def change_fmu(name: fmu.name, geojson: nil)
    travel 1.minute
    fmu.reload
    fmu.name = name
    fmu.geojson = geojson if geojson
    fmu.save!
  end

  def combined_versions = described_class.build_for(fmu.reload)

  describe "geometry versions" do
    it "groups an fmu edit and a geometry change by the same author into one entry" do
      change_fmu(name: "New name", geojson: moved_geojson)

      latest = combined_versions.last
      expect(latest.parent_version).to be_present
      expect(latest.geometry_version).to be_present
      expect(latest.changeset.keys).to include("name", "geojson")
    end

    it "shows a geometry-only change as its own entry" do
      change_fmu(geojson: moved_geojson)

      latest = combined_versions.last
      expect(latest.parent_version).to be_nil
      expect(latest.event).to eq("update")
      expect(latest.changeset.keys).to eq(["geojson"])
    end

    it "reifies the geometry before the change without touching the live record" do
      change_fmu(name: "New name", geojson: moved_geojson)

      resource = combined_versions.last.reify(fmu)

      expect(resource.name).to eq("Old name")
      expect(resource.geojson["geometry"]).to eq(original_geometry)
      expect(fmu.reload.geojson["geometry"]).to eq(moved_geojson["geometry"])
      expect(FmuGeometry.where(fmu_id: fmu.id).count).to eq(1)
    end

    it "reifies the geometry that was current at an entry without its own geometry change" do
      change_fmu(name: "New name")
      change_fmu(geojson: moved_geojson)

      name_change, _geometry_change = combined_versions.last(2)

      expect(name_change.reify(fmu).geojson["geometry"]).to eq(original_geometry)
    end
  end
end
