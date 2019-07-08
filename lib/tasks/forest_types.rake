namespace :forest_types do
  # Sets the attribute "forest_type" of fmus based on the geojson
  task update: :environment do
    query = <<-SQL
      select id, geojson->'properties'->>'fmu_type' as forest_type 
      from fmus 
      where geojson->'properties'->>'fmu_type' is not null;
    SQL

    forest_types_map = {
        'ventes_de_coupe' => Fmu::FOREST_TYPES[:vdc][:index],
        'ufa' => Fmu::FOREST_TYPES[:ufa][:index],
        'communal' => Fmu::FOREST_TYPES[:cf][:index]
    }

    result = ActiveRecord::Base.connection.execute(query)
    result.each do |row|
      Fmu.find(row['id']).update(forest_type: forest_types_map[row['forest_type']])
    end
  end
end