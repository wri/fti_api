class Admin::GeometryPreviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    file = params["file"]
    max_file_size = 200_000
    response = if file.blank? || file.size > max_file_size
      {errors: "File must exist and be smaller than #{max_file_size / 1000} KB"}
    else
      geojson = EsriShapefileUpload.geojson_from_file(file.path)
      if geojson.nil?
        {errors: "No geojson found in zip file"}
      else
        geometry = RGeo::GeoJSON.decode geojson
        bbox = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry.geometry)
        {
          geojson: geojson,
          bbox: [bbox.min_x, bbox.min_y, bbox.max_x, bbox.max_y]
        }
      end
    end

    render json: response
  end
end
