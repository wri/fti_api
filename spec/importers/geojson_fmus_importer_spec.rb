require 'rails_helper'

describe GeojsonFmusImporter, type: :importer do
  let!(:country) { create(:country, iso: "CMR", name: "Cameroon") }
  let!(:operator)  { create(:operator, id: 10624, name: "SEPFCO", country: country)}
  let!(:fmu) { create(:fmu, id: 100187, name: "asdf", forest_type: 2, country: country) }
  let!(:fmu_operator) {
    create(
      :fmu_operator,
      operator: operator,
      fmu: fmu,
      current: true,
      start_date: Date.yesterday - 1.day,
      end_date: Date.tomorrow
    )
  }

  let(:importer_type) { "geojson_fmus" }
  let(:uploaded_file) { fixture_file_upload("#{importer_type}/import_data.zip") }
  let(:importer) { FileDataImport::BaseImporter.build(importer_type, uploaded_file) }

  context "ZIP with Esri shape files" do
    it "returns right result" do
      importer.import

      expect(importer.results.to_json).to match_snapshot(
        "importers/geojson_fmus_importer",
        # because of the problem on CI that ogr2 returns dates in different formats
        # and I'm not sure how to restrict format using that tool
        # in that case I would just ignore those properties by treating them as dynamic ones
        dynamic_attributes: %w[end_date last_updat start_date]
      )
    end
  end
end
