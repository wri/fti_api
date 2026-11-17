require "rails_helper"

Rails.application.load_tasks if Rake::Task.tasks.empty?

describe "paper_trail:extract_fmu_geometry_history" do
  let(:task) { Rake::Task["paper_trail:extract_fmu_geometry_history"] }

  def run_task = task.invoke

  after { task.reenable }

  def feature(lng, name: "A")
    {
      "type" => "Feature",
      "geometry" => {"type" => "Point", "coordinates" => [lng, -4.0]},
      "properties" => {"fmu_name" => name}
    }
  end

  def legacy_version(item_id:, event: "update", object: nil, object_changes: nil, item_type: "Fmu", created_at: Time.zone.parse("2024-01-01"))
    PaperTrail::Version.create!(
      item_type: item_type, item_id: item_id, event: event, whodunnit: "42",
      object: object, object_changes: object_changes, created_at: created_at
    )
  end

  let!(:fmu) { create(:fmu, :geojson_no_props) }
  let(:fmu_geometry) { fmu.reload.fmu_geometry }

  let!(:created) do
    legacy_version(
      item_id: fmu.id, event: "create", created_at: Time.zone.parse("2020-06-01"),
      object_changes: {"name" => [nil, "A"], "geojson" => [nil, feature(13.0).to_json]}
    )
  end
  let!(:geometry_only) do
    legacy_version(
      item_id: fmu.id, created_at: Time.zone.parse("2021-01-01"),
      object: {"name" => "A", "geometry" => "0020000006000010e6", "geojson" => feature(13.0).to_json},
      object_changes: {"geojson" => [feature(13.0).to_json, feature(14.0).to_json], "updated_at" => ["2020-06-01", "2021-01-01"]}
    )
  end
  let!(:mixed) do
    legacy_version(
      item_id: fmu.id, created_at: Time.zone.parse("2022-01-01"),
      object: {"name" => "A", "geojson" => feature(14.0)},
      object_changes: {"name" => %w[A B], "geojson" => [feature(14.0), feature(15.0, name: "B")]}
    )
  end
  let!(:properties_only) do
    legacy_version(
      item_id: fmu.id, created_at: Time.zone.parse("2023-01-01"),
      object: {"name" => "B", "geojson" => feature(15.0, name: "B")},
      object_changes: {"name" => %w[B C], "geojson" => [feature(15.0, name: "B"), feature(15.0, name: "C")]}
    )
  end
  let!(:unrelated) do
    legacy_version(
      item_id: fmu.id,
      object: {"name" => "C", "geometry" => "0020000006000010e6", "geojson" => feature(15.0, name: "C")},
      object_changes: {"name" => %w[C D]}
    )
  end
  let!(:hard_deleted) do
    legacy_version(item_id: 999_999, object_changes: {"name" => %w[X Y], "geojson" => [feature(1.0), feature(2.0)]})
  end
  let!(:other_model) do
    legacy_version(item_type: "Operator", item_id: 1, object: {"geojson" => "kept", "geometry" => "kept"})
  end

  def snapshot = PaperTrail::Version.order(:id).pluck(:id, :item_type, :object, :object_changes)

  context "without FOR_REAL" do
    it "reports the counts without changing anything" do
      before = snapshot

      expect { run_task }.to output(
        a_string_including(
          "DRY RUN",
          "FmuGeometry versions created: 3",
          "Skipped, only geojson properties changed: 1",
          "Skipped, Fmu has no geometry row (hard-deleted or geojson removed): 1",
          "Fmu versions deleted (geojson was the only change): 1",
          "Fmu versions stripped of geojson/geometry: 5"
        )
      ).to_stdout
      expect(snapshot).to eq(before)
    end
  end

  context "with FOR_REAL=true" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("FOR_REAL").and_return("true")
    end

    it "rebuilds the geometry history as FmuGeometry versions" do
      expect { run_task }.to output(/RUNNING FOR REAL/).to_stdout

      versions = PaperTrail::Version.where(item_type: "FmuGeometry").order(:created_at)
      expect(versions.map(&:item_id).uniq).to eq([fmu_geometry.id])
      expect(versions.map(&:event)).to eq(%w[create update update])
      expect(versions.map(&:whodunnit).uniq).to eq(["42"])
      expect(versions.map(&:created_at)).to eq([created, geometry_only, mixed].map(&:created_at))

      expect(versions.first.object).to be_nil
      expect(versions.first.object_changes).to eq("fmu_id" => [nil, fmu.id], "geojson" => [nil, feature(13.0)])
      expect(versions.second.object).to eq("id" => fmu_geometry.id, "fmu_id" => fmu.id, "geojson" => feature(13.0))
      expect(versions.second.object_changes).to eq("geojson" => [feature(13.0), feature(14.0)])
      expect(versions.third.object_changes).to eq("geojson" => [feature(14.0), feature(15.0, name: "B")])
    end

    it "deletes geojson-only Fmu versions and strips geojson and geometry from the rest" do
      expect { run_task }.to output.to_stdout

      expect(PaperTrail::Version.exists?(geometry_only.id)).to be(false)
      expect(created.reload.object_changes).to eq("name" => [nil, "A"])
      expect(mixed.reload.object).to eq("name" => "A")
      expect(mixed.object_changes).to eq("name" => %w[A B])
      expect(properties_only.reload.object_changes).to eq("name" => %w[B C])
      expect(unrelated.reload.object).to eq("name" => "C")
      expect(hard_deleted.reload.object_changes).to eq("name" => %w[X Y])
      expect(other_model.reload.object).to eq("geojson" => "kept", "geometry" => "kept")
    end

    it "reifies the rebuilt history through the fmu" do
      expect { run_task }.to output.to_stdout

      reified = PaperTrail::Version.where(item_type: "FmuGeometry").order(:created_at).second.reify
      expect(reified.geojson).to eq(feature(13.0))
    end

    it "does nothing when run again" do
      expect { run_task }.to output.to_stdout
      task.reenable

      expect { run_task }.to output(/nothing to do/).to_stdout
    end
  end
end
