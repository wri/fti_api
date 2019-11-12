require 'csv'

namespace :import do
  namespace :v201908 do
    I18n.locale = :en

    desc 'Load geojson'
    task dry_run: :environment do
      Rails.logger.info('Importing the geojson')
      new_fmus = {}
      fmus = []
      replaced_fmus = {}
      new_associations = []
      filename = File.expand_path(File.join(Rails.root, 'db', 'files', '2019-08', 'fmus_CMR.json'))
      file = File.read filename
      data_hash = JSON.parse(file)
      country = Country.find_by(iso: 'CMR')
      data_hash['features'].each_with_index  do |row, index|
        properties = row['properties']

        name = properties['fmu_name'].strip
        operator = Operator.find_by(name: properties['company_name'])

        puts "-------------------------------------------------------------------------#{properties['company_name']}" if operator.blank?

        fmus << name
        fmu = Fmu.where(name: name, country_id: country.id).first if name.present?
        if fmu.present?
          replaced_fmus[index] = name
        else
          new_fmus[index] = name
        end

        #next unless fmu

        new_associations << { "#{name}": {old: fmu&.operator&.name, new: properties['company_name'] }} unless fmu&.operator == operator
      end

      old_fmus = Fmu.where(country_id: country.id).select {|f| !fmus.include?(f.name)}

      puts "----- New fmus:"
      new_fmus.sort.each{ |k, v| puts "---> #{k} - #{v}"}
      puts "NEW #{new_fmus.count}"
      puts "----- Modified fmus:"
      replaced_fmus.sort.each {|k, v| puts ">>>> #{k} - #{v}"}
      puts "MODIFIED #{replaced_fmus.count}"
      puts "----- Untouched fmus: "
      old_fmus.each { |f| puts "... #{f.id} - #{f.name}"}
      puts "UNTOUCHED #{old_fmus.count}"
      puts "----- New associations: "
      new_associations.each {|f| puts f }
      puts new_associations.count
    end

    desc 'Import Cameroon'
    task geojson: :environment do
      filename = File.expand_path(File.join(Rails.root, 'db', 'files', '2019-08', 'fmus_CMR.json'))
      file = File.read filename
      data_hash = JSON.parse(file)
      country = Country.find_by(iso: 'CMR')
      data_hash['features'].each_with_index do |row, index|
        properties = row['properties']
        puts "#{index.to_s.rjust(3, '0')}>> Importing fmu: #{properties['fmu_name'].strip.rjust(30, ' ')}. Operator #{ properties['company_name']}"

        name = properties['fmu_name'].strip
        operator_name = properties['company_name']&.strip
        operator = Operator.find_by(name: operator_name)
        puts "Creating Operator: #{operator_name}" unless (operator.present? || operator_name.blank?)
        operator ||= Operator.create!(name:operator_name,
                                      country_id: country.id,
                                      fa_id: "CMR/UNKNOWN/#{index.to_s.rjust(4, '0')}",
                                      operator_type: 'Logging company') unless operator_name.blank?


        fmu = Fmu.where(name: name, country_id: country.id).first if name.present?
        fmu = Fmu.where(country_id: country.id, name: "row-#{index}").first unless name.present?
        if fmu.blank?
          puts "Creating FMU: #{name}"
          fmu = Fmu.new
          fmu.country = country
          fmu.name = name.blank? ? "row-#{index}" : name
          fmu.forest_type = properties['fmu_type'].nil? ? 'fmu' : 'vdc'
        end

        fmu.geojson = row
        fmu.save!

        if fmu.operator != operator
          next if operator.blank? # This makes sure that we don't remove operators from fmus

          begin
            puts "Changing operator. FMU: #{name.rjust(27, ' ')}. Operator: #{operator.name}"
            if fmu.operator.present?
              puts "FMU: #{fmu.name.rjust(30, ' ')} had operator #{fmu.operator.name}"
              end_date = Date.parse(properties['start_date']) - 1.day rescue Date.today
              FmuOperator.where(fmu_id: fmu.id, current: true).find_each do |fo|
                fo.update!(current: false, end_date: end_date)
              end
            end
            FmuOperator.create!(current: true, fmu_id: fmu.id, operator_id: operator.id, start_date: properties['start_date'])
          rescue
            puts ">>>>>>>>>>>>>>>#{fmu.name}-> Couldn't update #{fmu.operator.name} to #{operator.name}."
          end
        end
      end
    end
  end
end