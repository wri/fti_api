namespace :fmus do
  desc 'remove_geojson_proerties'
  task remove_geojson_properties: :environment do
  
    Fmu.all.each do |fmu|
      fmu.geojson = fmu.geojson.except!('properties')
      fmu.save! 
    end
  end

  desc 'remove_duplicated_properties'
  task remove_duplicated_properties: :environment do

    Fmu.all.each do |fmu|
      fmu.properties = fmu.properties.except!('id', 'fmu_name', 'iso3_fmu', 'company_na', 'operator_id', 'certification_fsc', 'certification_pefc', 'certification_olb', 'certification_pafc', 'certification_fsc_cw', 'certification_tlv', 'certification_ls', 'observations', 'fmu_type_label')
      fmu.save!
    end
  end
end