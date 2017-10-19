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
end