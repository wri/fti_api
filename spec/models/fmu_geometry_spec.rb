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

  it "stores the geometry and centroid computed from the geojson" do
    expect(fmu_geometry.geometry).to be_present
    expect(fmu_geometry.centroid).to be_present
    expect(fmu.geometry.coordinates).to eq(fmu.geojson.dig("geometry", "coordinates"))
  end

  it "stores only the shape, keeping imported attributes apart from computed ones" do
    fmu.geojson = moved_geojson.merge("properties" => {"fmu_name" => "raw", "centroid" => {}, "num_ccf" => "005/11"}, "id" => 5)
    fmu.save!

    expect(fmu_geometry.reload.geojson).to eq(moved_geojson)
    expect(fmu_geometry.source_properties).to eq("num_ccf" => "005/11")
  end

  describe "source properties" do
    before do
      fmu.geojson = moved_geojson.merge("properties" => {"num_ccf" => "005/11"})
      fmu.save!
    end

    it "keeps them when the same shape is assigned again without attributes" do
      fmu.reload.geojson = fmu.geojson
      fmu.save!

      expect(fmu_geometry.reload.source_properties).to eq("num_ccf" => "005/11")
    end

    it "clears them when a new shape comes without attributes" do
      fmu.reload.geojson = fmu.geojson.merge("geometry" => {"type" => "Point", "coordinates" => [12.0, 1.0]})
      fmu.save!

      expect(fmu_geometry.reload.source_properties).to be_nil
    end

    it "updates them without versioning when only the attributes change" do
      geometry = fmu_geometry
      fmu.geojson = moved_geojson.merge("properties" => {"num_ccf" => "006/11"})

      expect { fmu.save! }.not_to change { geometry.versions.count }
      expect(geometry.reload.source_properties).to eq("num_ccf" => "006/11")
    end
  end

  it "parses a geojson string instead of storing it double-encoded" do
    fmu.geojson = moved_geojson.to_json
    fmu.save!

    expect(fmu_geometry.reload.geojson).to eq(moved_geojson)
  end

  it "does not version a change that only touches properties" do
    fmu.geojson = fmu.geojson.merge("properties" => {"fmu_name" => "other"})

    expect { fmu.save! }.not_to change { fmu_geometry.versions.count }
  end

  it "versions geojson changes without the geometry column" do
    original = fmu_geometry.geojson

    fmu.geojson = moved_geojson
    fmu.save!

    versions = fmu_geometry.versions.order(:id)
    expect(versions.map(&:event)).to eq(%w[create update])
    expect(versions.last.object["geojson"]).to eq(original)
    expect(versions.last.object_changes["geojson"].last).to eq(moved_geojson)
    expect(versions.map(&:object).compact + versions.map(&:object_changes)).to all(satisfy { |h| !h.key?("geometry") && !h.key?("centroid") })
    expect(fmu.versions.flat_map { |v| [v.object, v.object_changes] }.compact).to all(satisfy { |h| !h.key?("geojson") })
  end

  it "touches the fmu when only the geometry changes" do
    fmu.update_column(:updated_at, 1.day.ago)

    fmu.reload.geojson = moved_geojson
    fmu.save!

    expect(fmu.reload.updated_at).to be > 1.minute.ago
  end

  it "keeps the geometry of a soft-deleted fmu" do
    fmu.destroy!

    expect(Fmu.with_deleted.find(fmu.id).geojson).to be_present
  end

  it "does not create a geometry for an fmu without geojson" do
    expect(create(:fmu, geojson: nil).reload.fmu_geometry).to be_nil
  end
end
