require "rails_helper"

RSpec.describe ShapefileService do
  describe ".generate_shapefile" do
    let(:fmu1) { create(:fmu_geojson) }
    let(:fmu2) { create(:fmu_geojson) }

    it "returns a zip file with the shapefile components" do
      file_content = described_class.generate_shapefile([fmu1.reload, fmu2.reload])
      zip_file = Tempfile.new("shapes.zip")
      zip_file.write(file_content)
      zip_file.rewind

      Zip::File.open(zip_file) do |zip|
        expect(zip.glob("*.shp").count).to eq(1)
        expect(zip.glob("*.shx").count).to eq(1)
        expect(zip.glob("*.dbf").count).to eq(1)
        expect(zip.glob("*.prj").count).to eq(1)
      end
    end
  end
end
