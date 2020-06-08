# frozen_string_literal: true

module FileDataImport
  module Parser
    class Shp < FileDataImport::Parser::Base
      def convert_to_geojson
        `ogr2ogr -f GeoJSON #{path_to_geojson_file} #{path_to_file}`
      end

      def path_to_geojson_file
        @path_to_geojson_file ||= path_to_file.gsub(File.extname(path_to_file), ".geojson")
      end

      def features
        @features ||= JSON.parse(File.read(path_to_geojson_file))["features"] || []
      end

      def foreach_with_line
        return unless block_given?

        convert_to_geojson

        features.each.with_index(1) do |feature, line|
          id = feature.dig("properties", "id")
          yield({ id: id, geojson: feature }, line)
        end
      end
    end
  end
end
