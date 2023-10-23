class GeojsonValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    temp_geometry = RGeo::GeoJSON.decode value
    if temp_geometry.geometry.present?
      bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(temp_geometry.geometry)
      validate_bbox record, attribute, bbox
    else
      record.errors.add(attribute, "No geometry found in geojson")
    end
  rescue RGeo::Error::InvalidGeometry
    record.errors.add(attribute, "Failed linear ring test")
  rescue
    record.errors.add(attribute, "Incorrect geojson")
  end

  private

  def validate_bbox(record, attribute, bbox)
    return if bbox.max_x <= 180 && bbox.min_x >= -180 && bbox.max_y <= 90 && bbox.min_y >= -90

    record.errors.add(attribute, "The FMU's bbox is bigger than the globe. Please make sure your projection is 4326")
  end
end
