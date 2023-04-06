namespace :update do
  desc "Updates FMUs geojsons"
  task geojson: :environment do
    Fmu.find_each do |fmu|
      fmu.save!
    rescue => e
      puts "FMU ID: #{fmu.id}. Error: #{e.inspect}"
    end
  end

  desc "Updates FMUs geojsons' centroid"
  task centroid: :environment do
    query = "with subquery as (select id, ST_AsGeoJSON(st_centroid(ST_GeomFromGeoJSON(to_json(geojson->'geometry')::TEXT))) as centro from fmus)
update fmus
set geojson = jsonb_set(geojson, '{properties,centroid}', subquery.centro::jsonb, true)
from subquery
WHERE subquery.id = fmus.id"

    result = ActiveRecord::Base.connection.execute(query)

    puts result.inspect
  end

  desc "Updates the Sawmill geojson's"
  task sawmills: :environment do
    query = "with subquery as
              (select id, json_build_object(
                        'type', 'Feature',
                        'id', id,
                        'geometry', ST_AsGeoJSON(ST_MakePoint(lng, lat))::json,
                       'properties', (select row_to_json(sub) from (select name, is_active, operator_id) as sub)
              ) as geojson
              from sawmills
              group by id)
            update sawmills
            set geojson = subquery.geojson
            from subquery
            where subquery.id = sawmills.id"

    result = ActiveRecord::Base.connection.execute(query)

    puts result.inspect
  end
end
