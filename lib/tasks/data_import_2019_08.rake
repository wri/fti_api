require 'csv'

namespace :import do
  namespace :v201908 do
    I18n.locale = :en

    desc 'Load geojson'
    task dry_run: :environment do
      Rails.logger.info('Importing the geojson')
      new_fmus = { CMR: {}, COD: {}, CAF: {}, COG: {}, GAB: {} }
      fmus = { CMR: [], COD: [], CAF: [], COG: [], GAB: [] }
      replaced_fmus = { CMR: {}, COD: {}, CAF: {}, COG: {}, GAB: {} }
      new_associations = { CMR: [], COD: [], CAF: [], COG: [], GAB: [] }
      new_operators = { CMR: [], COD: [], CAF: [], COG: [], GAB: [] }
      filename = File.expand_path(File.join(Rails.root, 'db', 'files', '2019-08', 'fmus.json'))
      file = File.read filename
      data_hash = JSON.parse(file)
      data_hash['features'].each_with_index  do |row, index|
        properties = row['properties']

        country = Country.find_by(iso: properties['iso3_fmu'])
        iso = country.iso.to_sym
        name = properties['fmu_name'].strip
        operator = Operator.find_by(name: properties['company_na'])

        new_operators[iso] << properties['company_na']

        fmus[iso] << name
        fmu = Fmu.where(name: name, country_id: country.id).first if name.present?
        if fmu.present?
          replaced_fmus[iso][index] = name
        else
          new_fmus[iso][index] = name
        end

        new_associations[iso] << { "#{name}": {old: fmu&.operator&.name, new: properties['company_na'] }} unless fmu&.operator == operator
      end

      %i[CMR COD CAF COG GAB].each do |iso|
        puts ">>>>>>>>>>>>>>>>>> #{iso} >>>>>>>>>>>>>>>>>>>"

        country = Country.find_by iso: iso
        old_fmus = Fmu.where(country_id: country.id).select {|f| !fmus[iso].include?(f.name) }

        puts "..... New FMUs"
        new_fmus[iso].sort.each{ |k, v| puts "Line #{k} - #{v}"}
        puts "_____ New FMUs count: #{new_fmus[iso].count}"

        puts "..... Modified FMUs"
        replaced_fmus[iso].sort.each{ |k, v| puts "Line #{k} - #{v}"}
        puts "_____ Modified FMUs count: #{replaced_fmus[iso].count}"

        puts "..... FMUs to remove"
        old_fmus.each { |f| puts "#{f.id} - #{f.name}"}
        puts "_____ FMUs to remove count: #{old_fmus.count}"

        puts "..... New associations"
        new_associations[iso].each {|f| puts f }
        puts "_____ New associations count #{new_associations[iso].count}"

        puts ":::::::::::: Finished #{iso} :::::::::::::"
      end

    end

    desc 'Import all countries'
    task geojson: :environment do
      Fmu.transaction do
        puts 'Updating fmus old names to the new ones'
        if Rails.env.production?
          fmunames_file = File.expand_path(File.join(Rails.root, 'db', 'files', '2019-08', 'production_intersects_80_v2.json'))
        else
          fmunames_file = File.expand_path(File.join(Rails.root, 'db', 'files', '2019-08', 'staging_intersects_80_v2.json'))
        end
        file = File.read fmunames_file
        data_hash = JSON.parse(file)
        data_hash['features'].each_with_index do |row, index|
          properties = row['properties']
          next if properties['old_fmunam']&.strip == properties['new_fmunam']&.strip

          begin
            fmu = Fmu.with_translations.find(properties['old_fmuid'])
            #next if fmu.country.iso == 'CMR' # Not importing Cameroon at the time
            new_fmu_name = properties['new_fmunam']&.strip.presence || fmu.name.presence || fmu.geojson&.dig('properties', 'globalid')&.presence || "fmu-row-#{index}"
            puts "[#{fmu.country.iso}] Going to change the FMU name from '#{properties['old_fmunam']&.strip}' to '#{new_fmu_name}'. ID: #{fmu.id}"

            fmu.name = new_fmu_name
            fmu.save
          rescue NoMethodError
            puts "-- Cannot find fmu named #{properties['old_fmunam']}"
          end
        end

        puts "Going to update all the names of the fmus to remove the carriage returns"
        ActiveRecord::Base.connection.execute("UPDATE \"fmu_translations\" SET \"name\" = regexp_replace(\"name\", E'(^[\\n\\r]+)|([\\n\\r]+$)', '', 'g' );")

        fmus = { CMR: [], COD: [], CAF: [], COG: [], GAB: [] }

        filename = File.expand_path(File.join(Rails.root, 'db', 'files', '2019-08', 'fmus.json'))
        file = File.read filename
        data_hash = JSON.parse(file)
        data_hash['features'].each_with_index do |row, index|
          properties = row['properties']
          country = Country.find_by(iso: properties['iso3_fmu'])
          #next if properties['iso3_fmu'] == 'CMR' # Not importing Cameroon at the time

          puts "#{index.to_s.rjust(3, '0')}[#{country.iso}]>> Importing fmu: #{properties['fmu_name'].strip.rjust(30, ' ')}. Operator #{ properties['company_na']}"

          name = properties['fmu_name'].strip
          operator_name = properties['company_na']&.strip
          operator =  Operator.with_translations.find_by("lower(trim(name)) = ?", operator_name.downcase)
          puts "Creating Operator: #{operator_name}" unless (operator.present? || operator_name.blank?)
          operator ||= Operator.create!(name:operator_name,
                                        country_id: country.id,
                                        fa_id: "CMR/UNKNOWN/#{index.to_s.rjust(4, '0')}",
                                        operator_type: 'Logging company') unless operator_name.blank?


          fmu = Fmu.where(name: name, country_id: country.id).first if name.present?
          fmu = Fmu.where(country_id: country.id, name: "#{country.iso}-row-#{index}").first unless name.present?
          unless fmu
            globalid = properties['globalid']
            fmu = Fmu.where(country_id: country.id).where("geojson->'properties'->>'globalid' = '#{globalid}'").first if globalid.present?
            puts "-------------------------------------------------- FOUND FMU BY globalid #{fmu.name}" if fmu.present?
          end

          if fmu.blank?
            puts "Creating FMU: #{name}"
            fmu = Fmu.new
            fmu.country = country
            fmu.name = name.blank? ? "#{country.iso}-row-#{index}" : name
            if properties['iso3_fmu'] == 'CAF'
              fmu.forest_type = :pea
            else
              fmu.forest_type = (Fmu::FOREST_TYPES.select{|_,v| v[:geojson_label] == properties['fmu_type_label']}).first.first rescue 'fmu'
            end
          end
          fmus[country.iso.to_sym] << fmu.name

          fmu.geojson = row
          fmu.save!

          if fmu.operator != operator
            if operator.blank? # Ends the fmus contracts yesterday
              fmu.fmu_operator.update(end_date: Date.today - 1.day, current: false)
            else
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

        puts "---- Removing old fmus"
        %i[CMR COD CAF COG GAB].each do |iso|
          #next if iso == :CMR # Not importing Cameroon at the time
          country = Country.find_by iso: iso
          old_fmus = Fmu.where(country_id: country.id).select {|f| !fmus[iso].include?(f.name) }

          puts "[#{iso}] Removing #{old_fmus.count} fmus: #{old_fmus.map{|x| x.name}.join(', ')}"
          old_fmus.each(&:destroy)
        end
      end
    end
  end
end