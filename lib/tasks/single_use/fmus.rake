namespace :fmus do
  desc 'Onetimer to fix unsync geometries'
  task update_geometry: :environment do
    to_resync = [100392, 11554, 11743, 11553, 100119, 11537, 100116, 11521]
    to_resync.each do |fmu_id|
      fmu_to_resync = Fmu.find(fmu_id)
      puts "before >> coordinates #{fmu_to_resync.geometry.coordinates == fmu_to_resync.geojson["geometry"]["coordinates"]}"
      fmu_to_resync.update_geometry
      fmu_to_resync.save!
      fixed_fmu = Fmu.find(fmu_id)
      puts "after >> coordinates #{fixed_fmu.geometry.coordinates == fixed_fmu.geojson["geometry"]["coordinates"]}"
    end
  end
end
