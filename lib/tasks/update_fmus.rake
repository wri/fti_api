namespace :update do

  desc 'Updates FMUs geojsons'
  task geojson: :environment do
    Fmu.find_each do |fmu|
      begin
        fmu.save!
      rescue Exception => e
        puts "FMU ID: #{fmu.id}. Error: #{e.inspect}"
      end
    end
  end

  desc 'Updates FMUs geojsons\' centroid'
  task centroid: :environment do
    query = "with subquery as (select id, ST_AsGeoJSON(st_centroid(ST_GeomFromGeoJSON(to_json(geojson->'geometry')::TEXT))) as centro from fmus)
update fmus
set geojson = jsonb_set(geojson, '{geometry,properties,centroid}', subquery.centro::jsonb, true)
from subquery
WHERE subquery.id = fmus.id"

    result = ActiveRecord::Base.connection.execute(query)

    puts result.inspect
  end
end