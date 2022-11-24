require 'csv'

namespace :import do
  I18n.locale = :en


  desc 'Loads categories data from a csv file'
  task categories: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'categories.csv'))
    puts '* Loading Operator Categories... *'
    Category.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        Category.where(name: data_row['name'], category_type: Category.category_types[:operator]).first_or_create
      end
    end
    puts 'Categories loaded'
  end


  desc 'Loads species data from a csv file'
  task species: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'cites_listings.csv'))
    puts '* Loading Species... *'
    Species.transaction do
      batch, batch_size = [], 2_000
      country_lookup = Hash[Country.pluck(:name, :id)]
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country_names = data_row['countries'].split(',') if data_row['countries'].present?
        country_ids   = country_names.map { |c| country_lookup[c] } if country_names.present?

        data_species = {}
        data_species[:cites_id]        = data_row['cites_id']
        data_species[:species_kingdom] = data_row['species_kingdom']
        data_species[:species_class]   = data_row['species_class']
        data_species[:species_family]  = data_row['species_family']
        data_species[:name]            = data_row['name']
        data_species[:sub_species]     = data_row['sub_species']
        data_species[:scientific_name] = data_row['scientific_name']
        data_species[:cites_status]    = data_row['cites_status']
        data_species[:country_ids]     = country_ids if country_ids.present?

        batch << Species.new(data_species) if data_row['name'].present?

        if batch_size <= batch.size
          Species.import batch
          batch = []
        end
      end
    end
    puts 'Species loaded'
  end


  desc 'Import Generic Operator Documents'
  task generic_operator_documents: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'generic operator documents.csv'))
    RequiredOperatorDocumentGroup.transaction do
      CSV.foreach(filename, col_sep: ',', row_sep: :auto, headers: true, encoding: 'UTF-8').with_index do |row, i|
        puts "Line #{i} - #{row}"

        rodg = RequiredOperatorDocumentGroup.find_by!(name: row['Legal category'])
        rod = row['Type'] == 'FMU' ? RequiredOperatorDocumentFmu : RequiredOperatorDocumentCountry

        rod.create!(
          required_operator_document_group: rodg,
          valid_period: 365,
          name: row['Generic document']
        )
      end
    end
  end


  desc 'Import Operator Documents Types'
  task operator_document_types: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operator_document_types.csv'))

    puts '* Operator document types... *'
    country_congo = Country.find_by(iso: 'COG').id
    country_drc = Country.find_by(iso: 'COD').id
    country_generic = nil

    rodg = nil

    RequiredOperatorDocumentGroup.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h
        if data_row['group_en'].present?
          rodg = RequiredOperatorDocumentGroup.where(name: data_row['group_en']).first
          if rodg.blank?
            rodg =  RequiredOperatorDocumentGroup.new(name: data_row['group_en'])
            rodg.update_attributes!(name: data_row['group_fr'], locale: :fr)
          end
        end

        %w(generic congo drc).each do |country|
          %w(country fmu).each do |doc_type|
            rod_name = data_row["#{country}_#{doc_type}"]
            if rod_name.present?
              RequiredOperatorDocument.where(required_operator_document_group_id: rodg.id, valid_period: 365,
                                             name: rod_name, type: "RequiredOperatorDocument#{doc_type.capitalize}",
                                             country_id: eval("country_#{country}")).first_or_create!

            end
          end
        end
      end
    end
    puts ' Finished operator document types'
  end


  desc 'Loads monitors data from a csv file'
  task monitors: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'monitors.csv'))
    puts '* Loading Monitors... *'
    Observer.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        Observer.find_or_create_by!(data_row)
      end
    end
    puts 'Monitors loaded'
  end


  desc 'Loads operators data from a csv file'
  task operators: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operators.csv'))
    puts '* Loading Operators... *'
    Operator.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country = Country.find_by(name: data_row['country'])
        operator = Operator.where(name: data_row['operator']).first_or_create
        operator.operator_type = data_row['type']
        operator.country = country
        operator.fa_id = data_row['id']
        operator.save!
      end
    end
    puts 'Operators loaded'
  end


  desc 'Loads subcategories of type operator'
  task subcategory_operators: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'subcategory_operators.csv'))
    puts '* Subcategories operators... *'
    Subcategory.transaction do

      congo = Country.find_by(name: 'Congo')
      drc = Country.find_by(name: 'Democratic Republic of the Congo')
      cameroon = Country.find_by(name: 'Cameroon')
      ci = Country.find_by(name: 'Cote d\'Ivoire')

      subcategory = nil

      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        if data_row['illegality'].present?
          category = Category.where(name: data_row['category_name'], category_type: Category.category_types[:operator]).first_or_create!
          subcategory = Subcategory.where(name: data_row['illegality'],
                                          subcategory_type: Subcategory.subcategory_types[:operator],
                                          category_id: category.id).first_or_create!
          subcategory.update_attributes(name: data_row['illegality_fr'], locale: :fr)

          subcategory.save!

          if subcategory.severities.empty?
            (0..3).each do |s|
              sev = subcategory.severities.build(level: s, details: data_row["severity_#{s}"] || 'Not specified')
              sev.save!
            end
          end

        end

        %w(congo drc cameroon ci).each do |country|
          written_infraction = data_row["#{country} written_infraction"]
          infraction         = data_row["#{country} infraction"]
          sanctions          = data_row["#{country} sanctions"]
          min_fine           = data_row["#{country} min_fine"]
          max_fine           = data_row["#{country} max_fine"]
          penal_servitude    = data_row["#{country} penal_servitude"]
          other_penalties    = data_row["#{country} other_penalties"]
          apv                = data_row["#{country} apv"]

          if written_infraction.present? || infraction.present?
            law = Law.where(subcategory_id: subcategory.id, written_infraction: written_infraction, infraction: infraction,
                            sanctions: sanctions, min_fine: min_fine, max_fine: max_fine, penal_servitude: penal_servitude,
                            other_penalties: other_penalties, apv: apv, country_id: eval("#{country}.id")).first_or_create
          end
        end
     end
    end
    puts 'Operator Subcategories loaded'
  end


  desc 'Loads the government subcategories data from a csv file'
  task subcategory_governments: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'subcategory_governance.csv'))
    puts '* Government Subcategories ... *'
    Subcategory.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        category = Category.where(name: data_row['governance_pillar'], category_type: Category.category_types[:government]).first_or_create!
        subcategory = Subcategory.where(name: data_row['governance_problem'],
                                        subcategory_type: Subcategory.subcategory_types[:government],
                                        category_id: category.id).first_or_create!

        subcategory.save!

        subcategory.update_attributes(name: data_row['governance_problem_fr'], locale: :fr)
        if subcategory.severities.empty?
          (0..3).each do |s|
            sev = subcategory.severities.build(level: s, details: data_row["severity_#{s}"] || 'Not specified')
            sev.save!
          end
        end
      end
    end
    puts 'Government Subcategories loaded'
  end


  desc 'Loads operator observations data from a csv file'
  task operator_observations: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operator_observations.csv'))
    puts '* Operators observations... *'
    Observation.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country_names = data_row['countries'].split(',') if data_row['countries'].present?
        country_id    = Country.where(name: country_names).pluck(:id).first

        monitor_names = data_row['monitor_name'].split('/')
        monitor_ids   = Observer.where(name: monitor_names).pluck(:id) if monitor_names.any?

        operator_name = data_row['operator_name']
        operator_id   = Operator.where(name: operator_name, country_id: country_id).pluck(:id) if operator_name.present?

        subcategory_name = data_row['illegality']
        subcategory_id = Subcategory.where(name: subcategory_name, subcategory_type: Subcategory.subcategory_types[:operator]).pluck(:id).first if subcategory_name.present?

        report_link = data_row['document_link']
        report_name = data_row['document_name']
        report = nil

        if report_name.present? && report_link.present?
          begin
            puts ".........Going to load #{report_name}"

            report = ObservationReport.find_by(title: report_name)
            if report.blank?
              report = ObservationReport.new(title: report_name)
              report.remote_attachment_url = report_link
              report.observers = Observer.where(id: monitor_ids)
              report.save
            end
          rescue Exception => e
            puts "-------Couldn't load #{report_name}: #{e.inspect}"
          end
        end

        unless subcategory_id.present?
          puts "Couldn't load subcategory ::#{subcategory_name}::"
          next
        end

        date = data_row['publication_date']
        data_oo = {}
        data_oo[:observation_type]  = Observation.observation_types[:operator]
        data_oo[:publication_date]  = date.count(' ') > 0 ? Date.parse(date) : Date.parse("Jan #{date}")
        data_oo[:country_id]        = country_id
        data_oo[:details]           = data_row['description']
        data_oo[:evidence]          = data_row['evidence']
        data_oo[:concern_opinion]   = data_row['concern_opinion']
        data_oo[:litigation_status] = data_row['litigation_status']
        data_oo[:pv]                = data_row['pv']
        data_oo[:observer_ids]      = monitor_ids       if monitor_ids.present? && monitor_ids.any?
        data_oo[:operator_id]       = operator_id.first if operator_id.present?
        data_oo[:subcategory_id]    = subcategory_id if subcategory_id.present?
        data_oo[:country_id] = country_id if country_id.present?

        oo = Observation.create(data_oo)
        severity_id = oo.subcategory.severities.find_by(level: data_row['severities']).id
        oo.update_attributes!(severity_id: severity_id)

        fmu = Fmu.find_by(name: data_row['concession'])
        oo.update_attributes(fmu_id: fmu.id) if fmu.present?

        oo.observation_report = report if report.present?
        oo.save
      end
    end
    puts 'Operator observations loaded'
  end

  # This also creates the government entities
  desc 'Loads government observations data from a csv file'
  task government_observations: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'governance_observations.csv'))
    puts '* Government observations... *'
    Observation.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country_names = data_row['countries'].split(',') if data_row['countries'].present?
        country_id    = Country.where(name: country_names).pluck(:id).first

        monitor_names = data_row['monitor_name'].split('/')
        monitor_ids   = Observer.where(name: monitor_names).pluck(:id) if monitor_names.any?

        operator_name = data_row['operator_name']
        operator_id   = Operator.where(name: operator_name, country_id: country_id).first_or_create.id if operator_name.present?

        government_entity = data_row['government_entity']
        government_id     = Government.where(government_entity: government_entity, country_id: country_id).first_or_create.id if government_entity.present?

        subcategory_name = data_row['governance_problem']
        subcategory_id = Subcategory.where(name: subcategory_name, subcategory_type: Subcategory.subcategory_types[:government]).pluck(:id).first if subcategory_name.present?

        report_link = data_row['document_link']
        report_name = data_row['document_name']
        report = nil

        if report_name.present? && report_link.present?
          begin
            puts ".........Going to load #{report_name}"

            report = ObservationReport.find_by(title: report_name)
            if report.blank?
              report = ObservationReport.new(title: report_name)
              report.remote_attachment_url = report_link
              report.observers = Observer.where(id: monitor_ids)
              report.save
            end
          rescue Exception => e
            puts "-------Couldn't load #{report_name}: #{e.inspect}"
          end
        end


        date = data_row['publication_date']
        data_go = {}
        data_go[:observation_type]  = Observation.observation_types[:government]
        data_go[:publication_date]  = date.count(' ') > 0 ? Date.parse(date) : Date.parse("Jan #{date}")
        data_go[:country_id]        = country_id
        data_go[:details]           = data_row['description']
        data_go[:evidence]          = data_row['evidence']
        data_go[:concern_opinion]   = data_row['concern_opinion']
        data_go[:observer_ids]      = monitor_ids     if monitor_ids.present?
        data_go[:operator_id]       = operator_id     if operator_id.present?
        data_go[:government_id]     = government_id   if government_id.present?
        data_go[:subcategory_id]    = subcategory_id  if subcategory_id.present?
        data_go[:country_id] = country_id if country_id.present?

        go = Observation.create!(data_go)
        severity_id = go.subcategory.severities.find_by(level: data_row['severities']).id
        go.update_attributes!(severity_id: severity_id)

        go.observation_report = report if report.present?
        go.save
      end
    end
    puts 'Government observations loaded'
  end


  desc 'Loads fmus from a csv file'
  task fmus: :environment do

    puts '* FMUs... *'
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'concession.geojson'))

    file = File.read(filename)
    data_hash = JSON.parse(file)
    data_hash['features'].each do |row|
      properties = row['properties']
      name = properties['fmu_name']
      operator_name = properties['company_na']
      country_iso = properties['iso3_fmu']

      next if Fmu.where(name: name).any?

      fmu = Fmu.where(name: name).first_or_create
      if operator_name.present?
        operator = Operator.find_by(name: operator_name)
        fmu.operator = operator  if operator.present?
      end
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

  # Adds the FA id to the Operator, and checks the FMUs
  desc 'Loads operator ids and fmus'
  task operator_id_fmus: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operator_id_fmus.csv'))
    puts '* Operator Ids and Fmus... *'

    Operator.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        operator = Operator.find_by(name: data_row['operator'])
        if operator.fa_id.blank?
          operator.fa_id = data_row['id']
          operator.save
        end

        begin
          fmu = Fmu.joins(:translations).where("name like '%#{data_row['fmu']}%'").first
          if fmu.operator_id.blank?
            fmu.operator_id = operator.id
            fmu.save
          end
        rescue Exception => e
          puts "Error in operator id fmu: #{e.inspect} - #{data_row['fmu']}"
        end
      end
    end
  end


  # This task is not to be used in the import

  desc 'Create Operator Documents'
  task operator_documents: :environment do
    puts '* Operator documents'

    puts '... creating required operator documents per country'
    Operator.find_each do |operator|
      country = RequiredOperatorDocumentCountry.where(country_id: operator.country_id).any? ? operator.country_id : nil
      RequiredOperatorDocumentCountry.where(country_id: country).find_each do |rodc|
        OperatorDocumentCountry.where(required_operator_document_id: rodc.id, operator_id: operator.id).first_or_create
      end
    end

    puts '... creating required operator documents per fmu'
    Fmu.find_each do |fmu|
      country = RequiredOperatorDocumentFmu.where(country_id: fmu.country_id).any? ? fmu.country_id : nil
      RequiredOperatorDocumentFmu.where(country_id: country).find_each do |rodf|
        if fmu.operator_id.present?
          OperatorDocumentFmu.where(required_operator_document_id: rodf.id, operator_id: fmu.operator_id, fmu_id: fmu.id).first_or_create
        end
      end
    end
    puts 'Finished operator documents'
  end

  # Imports the operator document files
  desc 'Import Operator Documents'' Files'
  task operator_document_files: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operator_documents.csv'))
    puts '* Operator Documents Files... *'
    i = 0
    OperatorDocument.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        i = i+1
        puts '-> ' + i.to_s
        data_row = row.to_h
        operator = Operator.find_by(fa_id: data_row['ID'])
        fmu = nil
        fmu = Fmu.joins(:translations).where("name like '%#{data_row['FA_FMU']}%'").first if data_row['FA_FMU'].present?
        required_operator_document = RequiredOperatorDocument.find_by(name: data_row['OTP_Document name'])
        link = data_row['Link to the document']
        start_date = data_row['Start date']

        if operator.nil?
          puts ">>>>>>>> OPERATOR #{data_row['ID']}"
          next
        elsif required_operator_document.nil?
          puts ">>>>>>>> DOCUMENT #{data_row['OTP_Document name']}"
          next
        elsif fmu.nil? && data_row['FA_FMU'].present?
          puts ">>>>>>>> FMU #{data_row['FA_FMU']}"
          next
        end

        operator_document =
            if fmu.present?
              OperatorDocument.find_by(operator_id: operator.id,
                                       required_operator_document_id: required_operator_document.id, fmu_id: fmu.id)
            else
              OperatorDocument.find_by(operator_id: operator.id,
                                       required_operator_document_id: required_operator_document.id)
            end

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


  # Imports the operator document files
  desc 'Import Operator Documents'' Files V2'
  task operator_document_files_v2: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operator_documents_v2.csv'))
    puts '* Operator Documents Files... *'
    i = 0
    OperatorDocument.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        i = i+1
        puts '-> ' + i.to_s
        data_row = row.to_h
        operator = Operator.find_by(fa_id: data_row['ID'])
        fmu = nil
        fmu = Fmu.joins(:translations).where("lower(name) like '%#{data_row['Concession'].downcase}%'").first if data_row['Type'] == 'RequiredOperatorDocumentFmu'
        required_operator_document = RequiredOperatorDocument.find_by(name: data_row['Required operator document'])
        start_date = data_row['Start date']
        expire_date = data_row['Expire date']
        file = data_row['Document File Path']

        if operator.nil?
          puts ">>>>>>>> OPERATOR #{data_row['Company']}"
          next
        elsif required_operator_document.nil?
          puts ">>>>>>>> DOCUMENT #{data_row['Required operator Document']}"
          next
        elsif fmu.nil? && data_row['Type'] == 'RequiredOperatorDocumentFmu'
          puts ">>>>>>>> FMU #{data_row['Concession']}"
          next
        end

        operator_document =
            if fmu.present?
              OperatorDocument.find_by(operator_id: operator.id,
                                       required_operator_document_id: required_operator_document.id, fmu_id: fmu.id,
                                       current: true)
            else
              OperatorDocument.find_by(operator_id: operator.id,
                                       required_operator_document_id: required_operator_document.id,
                                       current: true)
            end

        if operator_document.nil?
          puts '>>>>>>>> OPERATOR DOCUMENT'
          next
        end

        begin
          unless operator_document.status == OperatorDocument.statuses[:doc_pending]
            operator_document.attachment = File.open(File.join(Rails.root, 'db', 'files', 'operator_document_files', file))
          end
        rescue Exception => e
          puts "-------Couldn't load Operator Document: #{file}: #{e.inspect}"
        end

        begin
          operator_document.uploaded_by = 3
          operator_document.start_date = Date.strptime(start_date, '%m/%d/%Y')
          operator_document.expire_date = Date.strptime(expire_date , '%m/%d/%Y')
          operator_document.status = OperatorDocument.statuses[:doc_pending]
          operator_document.save!
        rescue
          puts "<<<<<<<<<<<<< Couldn't save operator document: #{operator_document.errors.inspect}"
        end
      end
    end
  end
end
