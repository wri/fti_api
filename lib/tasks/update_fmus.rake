namespace :update do
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
