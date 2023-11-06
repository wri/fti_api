module EsriShapefileUpload
  extend ActiveSupport::Concern

  included do
    attr_reader :esri_shapefiles_zip
  end

  def esri_shapefiles_zip=(esri_shapefiles_zip)
    self.geojson = geojson_from_file(esri_shapefiles_zip.path)
    @esri_shapefiles_zip = esri_shapefiles_zip
  end

  def geojson_from_file(filepath)
    FileDataImport::Parser::Zip.new(filepath).foreach_with_line do |attributes, index|
      # takes only the first feature from the Esri shapefile.
      return attributes[:geojson].slice("type", "geometry").merge("properties" => {})
    end
  end
  module_function :geojson_from_file
end
