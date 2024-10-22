require "gdal"
require "rgeo"
require "zip"

class ShapefileService
  # Generate a shapefile from a collection of objects that respond to the `geometry` method
  # The `geometry` method should return an RGeo::Feature object
  def self.generate_shapefile(shapes)
    # Create a temporary directory to store the shapefile components
    Dir.mktmpdir do |dir|
      shapes_name = (shapes.size == 1) ? shapes.first.name : "shapes"

      shapefile_path = File.join(dir, "#{shapes_name}.shp")

      # Initialize GDAL
      driver = Gdal::Ogr.get_driver_by_name("ESRI Shapefile")
      datasource = driver.create_data_source(shapefile_path)
      layer = datasource.create_layer("shapes", nil, Gdal::Ogr::WKBPOLYGON)

      # Define the fields
      field_defn = Gdal::Ogr::FieldDefn.new("id", Gdal::Ogr::OFTINTEGER)
      layer.create_field(field_defn)
      field_defn = Gdal::Ogr::FieldDefn.new("name", Gdal::Ogr::OFTSTRING)
      layer.create_field(field_defn)
      field_defn = Gdal::Ogr::FieldDefn.new("operator", Gdal::Ogr::OFTSTRING)
      layer.create_field(field_defn)

      shapes.each do |shape|
        feature = Gdal::Ogr::Feature.new(layer.get_layer_defn)
        feature.set_field("id", shape.id)
        feature.set_field("name", shape.name)
        feature.set_field("operator", shape.operator&.name)
        geometry = Gdal::Ogr.create_geometry_from_wkt(shape.geometry.as_text)
        feature.set_geometry(geometry)
        layer.create_feature(feature)
      end

      datasource.sync_to_disk

      # Write the .prj file
      prj_content = generate_prj_content
      prj_path = File.join(dir, "#{shapes_name}.prj")
      File.write(prj_path, prj_content)

      # Collect the generated shapefile parts
      files = Dir.glob("#{dir}/*")

      zipfile_path = File.join(dir, "#{shapes_name}.zip")
      Zip::File.open(zipfile_path, Zip::File::CREATE) do |zipfile|
        files.each do |file|
          zipfile.add(File.basename(file), file)
        end
      end

      # Read the zipfile content
      zip_content = File.read(zipfile_path)

      # Return the zip content
      zip_content
    end
  end

  def self.generate_prj_content
    'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563,' \
      'AUTHORITY["EPSG","7030"]],AUTHORITY["EPSG","6326"]],PRIMEM["Greenwich",0,' \
      'AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,' \
      'AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4326"]]'
  end
end
