require 'csv'

namespace :import do
  namespace :v2 do
    I18n.locale = :en

    desc 'Load operators from a csv file'
    task operators: :environment do
      puts '* operators... *'
      filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'v2', 'societes.csv'))
      puts '* Loading Operators... *'
      country = Country.find_by(iso: 'CMR')
      Operator.transaction do

        CSV.foreach(filename, col_sep: ',', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
          data_row = row.to_h

          operator = Operator.where(name: data_row['societe']).first_or_create
          operator.operator_type = 'Unknown'
          operator.country = country
          operator.operator_id = data_row['nrc_ste']
          operator.is_active = true
          operator.save!
        end
      end
      puts 'Operators loaded'
    end

    desc 'Loads fmus data from a csv file'
    task fmus: :environment do
      puts '* FMUs... *'
      filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'v2', 'forest_production.geojson'))

      file = File.read(filename)
      data_hash = JSON.parse(file)
      data_hash['features'].each do |row|
        properties = row['properties']
        name = properties['nom_foret']
        country_iso = 'CMR'

        next if Fmu.where(name: name).any?

        fmu = Fmu.where(name: name).first_or_create

        if country_iso.present?
          country = Country.find_by(iso: country_iso)
          fmu.country = country if country.present?
        end
        fmu.save!(validate: false)

        # Updating the geojson

        geojson = row
        geojson['properties']['id'] = fmu.id
        geojson['properties']['operator_id'] = fmu.operator.id if fmu.operator.present?
        fmu.geojson = geojson
        fmu.save!(validate: false)

      end
      puts 'Finished FMUs'
    end

    desc 'Load operator-fmus from a csv file'
    task operator_fmus: :environment do
      puts '* operator-fmus... *'
      filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'v2', 'concessions.csv'))
      puts '* Loading Operator-FMUs... *'
      FmuOperator.transaction do

        CSV.foreach(filename, col_sep: ',', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
          data_row = row.to_h

          operator = Operator.where(name: data_row['exploitant']).first
          Fmu.where("geojson @> '{\"properties\": {\"nom_conces\": \"#{data_row['nom_conces']}\"}}'").each do |fmu|
            start_date = Time.at(data_row['date_attr'].to_f / 1000) if data_row['date_attr'].present?

            if operator.present? && fmu.present?
              FmuOperator.create operator: operator, fmu: fmu, start_date: start_date, current: true
            end
          end
        end
      end
      puts 'Operators loaded'
    end

    # Imports the operator document files
    desc 'Import Operator Documents'' Files'
    task operator_document_files: :environment do
      filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'v2', 'documents.csv'))
      puts '* Operator Documents Files... *'
      i = 0

      OperatorDocument.transaction do
        puts ' ... Creating Required Operator Documents and Groups ...'
        rodg = RequiredOperatorDocumentGroup.last

        rod1 = RequiredOperatorDocumentFmu.new(
            required_operator_document_group: rodg, country: Country.find_by(iso: 'CMR'),
            name: 'Cameroon 1', valid_period: 356)

        rod2 = RequiredOperatorDocumentFmu.new(
            required_operator_document_group: rodg, country: Country.find_by(iso: 'CMR'),
            name: 'Cameroon 2', valid_period: 356)

        rod1.save!
        rod2.save!

        CSV.foreach(filename, col_sep: ',', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
          i = i+1
          puts '-> ' + i.to_s
          data_row = row.to_h
          fmu = Fmu.with_translations(I18n.locale).find_by(name: data_row['nom_foret'])

          next unless OperatorDocumentFmu.find_by(required_operator_document: rod1, fmu: fmu).present?

          operator_document = if OperatorDocumentFmu.find_by(required_operator_document: rod1, fmu: fmu).status.eql? 'doc_not_provided'
                                         OperatorDocumentFmu.where(required_operator_document: rod1, fmu: fmu).first
                                       else
                                         OperatorDocumentFmu.where(required_operator_document: rod2, fmu: fmu).first
                                       end

          link = data_row['url']
          start_date = Date.today

          begin
            next if operator_document.status == OperatorDocument.statuses[:doc_pending]
            operator_document.remote_attachment_url = link
          rescue Exception => e
            puts "-------Couldn't load Operator Document: #{link}: #{e.inspect}"
          end

          begin
            operator_document.start_date = start_date
            operator_document.status = OperatorDocument.statuses[:doc_pending]
            operator_document.save!
          rescue
            puts "<<<<<<<<<<<<< Operator Document not found"
          end
        end
      end
    end

    desc 'Runs all the tasks to import the new files'
    task all: :environment do
      country = Country.find_by iso: 'CMR'
      country.is_active = true
      country.save

      Rake::Task['import:v2:operators'].invoke
      Rake::Task['import:v2:fmus'].invoke
      Rake::Task['import:v2:operator_fmus'].invoke
      Rake::Task['import:v2:operator_document_files'].invoke
    end
  end
end