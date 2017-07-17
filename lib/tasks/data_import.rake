require 'csv'

namespace :import do
  I18n.locale = :en

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

        #Operator.find_or_create_by!(data_row)
        operator = Operator.where(name: data_row['name']).first_or_create
        operator.operator_type = data_row['operator_type']
        operator.save!
      end
    end
    puts 'Operators loaded'
  end

  desc 'Loads operator categories data from a csv file'
  task categories: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'categories.csv'))
    puts '* Loading Operator Categories... *'
    Category.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        Category.where(name: data_row['name'], category_type: Category.category_types[:operator]).first_or_create
      end
    end
    puts 'Operator Categories loaded'
  end

  desc 'Loads subcategories of type operator'
  task subcategory_operators: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'annex_operators.csv'))
    puts '* Subcategories operators... *'
    Subcategory.transaction do

      congo = Country.find_by(name: 'Congo')
      drc = Country.find_by(name: 'Democratic Republic of the Congo')
      cameroon = Country.find_by(name: 'Cameroon')
      civ = Country.find_by(name: 'Cote d\'Ivoire')

      CSV.foreach(filename, col_sep: ',', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        category = Category.where(name: data_row['category_name'], category_type: Category.category_types[:operator]).first_or_create!
        subcategory = Subcategory.where(name: data_row['illegality'],
                                        subcategory_type: Subcategory.subcategory_types[:operator],
                                        category_id: category.id).first_or_create!
        subcategory.update_attributes(name: data_row['illegality_fr'], locale: :fr)

        if subcategory.severities.empty?
          (0..3).each do |s|
            subcategory.severities.build(level: s, details: data_row["severity_#{s}"] || 'Not specified')
          end
        end


        subcategory.save!

        %w(congo drc cameroon civ).each do |country|
          cs = CountrySubcategory.first_or_create(subcategory_id: subcategory.id, country_id: eval("#{country}.id"))
          cs.law = data_row["#{country}_law"]
          cs.penalty = data_row["#{country}_penalties"]
          cs.apv = data_row["#{country}_apv"]
          cs.save! if cs.law.present? || cs.penalty.present?
        end
     end
    end
    puts 'Operator Subcategories loaded'
  end

  desc 'Loads the government subcategories data from a csv file'
  task subcategory_governments: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'annex_governance.csv'))
    puts '* Government Subcategories ... *'
    Subcategory.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        category = Category.where(name: data_row['governance_pillar'], category_type: Category.category_types[:government]).first_or_create!
        subcategory = Subcategory.where(name: data_row['governance_problem'],
                                        subcategory_type: Subcategory.subcategory_types[:government],
                                        category_id: category.id).first_or_create!

        subcategory.update_attributes(name: data_row['governance_problem_fr'], locale: :fr)
        if subcategory.severities.empty?
          (0..3).each do |s|
            subcategory.severities.build(level: s, details: data_row["severity_#{s}"] || 'Not specified')
          end
        end
        subcategory.save!
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

        monitor_name = data_row['monitor_name']
        monitor_id   = Observer.where(name: monitor_name).pluck(:id) if monitor_name.present?

        operator_name = data_row['operator_name']
        operator_id   = Operator.where(name: operator_name).pluck(:id) if operator_name.present?

        subcategory_name = data_row['illegality']
        subcategory_id = Subcategory.where(name: subcategory_name, subcategory_type: Subcategory.subcategory_types[:operator]).pluck(:id).first if subcategory_name.present?

        next unless subcategory_id.present?

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
        data_oo[:observer_id]       = monitor_id.first  if monitor_id.present?
        data_oo[:operator_id]       = operator_id.first if operator_id.present?
        data_oo[:subcategory_id]    = subcategory_id if subcategory_id.present?
        data_oo[:country_id] = country_id if country_id.present?

        oo = Observation.create(data_oo)
        severity_id = oo.subcategory.severities.find_by(level: data_row['severities']).id
        oo.update_attributes!(severity_id: severity_id)

        fmu = Fmu.find_by(name: data_row['concession'])
        oo.update_attributes(fmu_id: fmu.id) if fmu.present?
      end
    end
    puts 'Operator observations loaded'
  end

  desc 'Loads government observations data from a csv file'
  task government_observations: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'governance_observations.csv'))
    puts '* Government observations... *'
    Observation.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country_names = data_row['countries'].split(',') if data_row['countries'].present?
        country_id    = Country.where(name: country_names).pluck(:id).first

        monitor_name = data_row['monitor_name']
        monitor_id   = Observer.where(name: monitor_name).pluck(:id).first if monitor_name.present?

        operator_name = data_row['operator_name']
        operator_id   = Operator.where(name: operator_name, operator_type: 'Company').first_or_create.id if operator_name.present?

        government_entity = data_row['government_entity']
        government_id     = Government.where(government_entity: government_entity, country_id: country_id).first_or_create.id if government_entity.present?

        subcategory_name = data_row['governance_problem']
        subcategory_id = Subcategory.where(name: subcategory_name, subcategory_type: Subcategory.subcategory_types[:government]).pluck(:id).first if subcategory_name.present?


        data_go = {}
        data_go[:observation_type]  = Observation.observation_types[:government]
        data_go[:publication_date]  = DateTime.strptime(data_row['publication_date'],'%y/%m/%d')
        data_go[:country_id]        = country_id
        data_go[:details]           = data_row['description']
        data_go[:evidence]          = data_row['evidence']
        data_go[:concern_opinion]   = data_row['concern_opinion']
        data_go[:observer_id]       = monitor_id    if monitor_id.present?
        data_go[:operator_id]       = operator_id   if operator_id.present?
        data_go[:government_id]     = government_id if government_id.present?
        data_go[:subcategory_id]    = subcategory_id if subcategory_id.present?
        data_go[:country_id] = country_id if country_id.present?

        go = Observation.create(data_go)
        severity_id = go.subcategory.severities.find_by(level: data_row['severities']).id
        go.update_attributes!(severity_id: severity_id)
      end
    end
    puts 'Government observations loaded'
  end


  desc 'Loads operators\' countries from a csv file'
  task operator_countries: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'companies.csv'))
    puts '* Operator countries... *'
    country_congo = Country.find_by(iso: 'COG')
    country_drc = Country.find_by(iso: 'COD')
    Operator.transaction do
      CSV.foreach(filename, col_sep: ',', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        if data_row['Congo (Atlas)'].present?
          operator = Operator.find_by(name: data_row['Congo (Atlas)'])
          if operator.present?
            operator.update(country: country_congo)
          end
        end

        if data_row['DRC (Atlas)'].present?
          operator = Operator.find_by(name: data_row['DRC (Atlas)'])
          if operator.present?
            operator.update(country: country_drc)
          end
        end
      end
    end
  end


  desc 'Loads fmus from a csv file'
  task fmus: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'concession.geojson'))

    file = File.read(filename)
    data_hash = JSON.parse(file)
    data_hash['features'].each do |row|
      properties = row['properties']
      name = properties['fmu_name']
      operator_name = properties['company_na']
      country_iso = properties['iso3_fmu']

      fmu = Fmu.where(name: name).first_or_create
      if operator_name.present?
        operator = Operator.find_by(name: operator_name)
        fmu.operator = operator  if operator.present?
      end
      if country_iso.present?
        country = Country.find_by(iso: country_iso)
        fmu.country = country if country.present?
      end
      fmu.save!

      # Updating the geojson

      geojson = row
      geojson['properties']['id'] = fmu.id
      geojson['properties']['operator_id'] = fmu.operator.id if fmu.operator.present?
      fmu.geojson = geojson
      fmu.save!

    end
  end


  desc 'Import Operator Documents Types'
  task operator_document_types: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operator_document_types.csv'))

    puts '* Operator document types... *'
    country_congo = Country.find_by(iso: 'COG')
    country_drc = Country.find_by(iso: 'COD')
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
            rod = data_row["#{country}_#{doc_type}"]
            if rod.present?
              RequiredOperatorDocument.where(required_operator_document_group_id: rodg.id,
                                             name: rod, type: "RequiredOperatorDocument#{doc_type.capitalize}",
                                             country_id: eval("country_#{country}")).first_or_create!
            end
          end
        end
      end
    end

    puts ' Finished operator document types'
  end
end