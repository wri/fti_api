namespace :fmus do
  desc 'Checks sync between properties and fmu_operator current'
  task current: :environment do
    with_current_but_not_sync = []
    without_current_and_not_sync = []
    Fmu.all.each do |fmu|
      #has current in fmu_operator
      if fmu.fmu_operator&.operator_id
        unless fmu.fmu_operator&.operator_id == fmu.properties['operator_id']
          with_current_but_not_sync.push(fmu.id)
          puts "fmu.id >> #{fmu.id} has current NOT sync with properties"
          if ENV["FOR_REAL"]
            fmu.save
            fmu.reload
            if fmu.fmu_operator&.operator_id == fmu.properties['operator_id']
              puts "fixed as expected" 
            else
              puts "something went wrong my friend!"
            end
          end
        end
      else
        #has no current in fmu_operator
        unless fmu.properties['operator_id'].nil? or fmu.properties['company_na'].nil?
          without_current_and_not_sync.push(fmu.id)
          puts "fmu.id >> #{fmu.id} has NO current but"
          puts " has operator_id in properties >>  #{fmu.properties['operator_id']}" unless fmu.properties['operator_id'].nil?
          puts " has company_na in properties >>  #{fmu.properties['company_na']}" unless fmu.properties['company_na'].nil?
          if ENV["FOR_REAL"]
            fmu.save
            fmu.reload
            if fmu.properties['operator_id'].nil? and fmu.properties['company_na'].nil?
              puts "fixed as expected" 
            else
              puts "something went wrong my friend!"
            end
          end
        end
      end
    end

    puts "with_current_but_not_sync"
    puts with_current_but_not_sync

    puts "without_current_and_not_sync"
    puts without_current_and_not_sync
  end

  desc 'Checks geojson properties'
  task geojson: :environment do
    with_geojson_operator = []
    without_geojson_operator = []
    Fmu.all.each do |fmu|
      if fmu['properties']['operator_id'].nil?
        without_geojson_operator.push(fmu.id)
      else
        with_geojson_operator.push(fmu.id)
      end      
    end

    puts "with_geojson_operator"
    puts with_geojson_operator

    puts "without_geojson_operator"
    puts without_geojson_operator
  end
end