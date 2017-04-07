require 'csv'

namespace :import_species_csv do
  I18n.locale = :en
  desc 'Loads species data from a csv file'
  task create_species: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'cites_listings.csv'))
    puts '* Loading Species... *'
    Species.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country_names = data_row['countries'].split(',') if data_row['countries'].present?
        country_ids   = Country.where(name: country_names).pluck(:id) if country_names.present?

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

        Species.create!(data_species) if data_row['name'].present?
      end
    end
    puts 'Species loaded'
  end
end

namespace :import_monitors_csv do
  I18n.locale = :en
  desc 'Loads monitors data from a csv file'
  task create_monitors: :environment do
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
end

namespace :import_operators_csv do
  I18n.locale = :en
  desc 'Loads operators data from a csv file'
  task create_operators: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operators.csv'))
    puts '* Loading Operators... *'
    Operator.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        Operator.find_or_create_by!(data_row)
      end
    end
    puts 'Operators loaded'
  end
end

namespace :import_categories_csv do
  I18n.locale = :en
  desc 'Loads categories data from a csv file'
  task create_categories: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'categories.csv'))
    puts '* Loading Categories... *'
    Category.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        Category.find_or_create_by!(data_row)
      end
    end
    puts 'Categories loaded'
  end
end

namespace :import_laws_csv do
  I18n.locale = :en
  desc 'Loads laws data from a csv file'
  task create_laws: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'laws.csv'))
    puts '* Loading Laws... *'
    Law.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        Law.find_or_create_by!(data_row) if data_row['legal_reference'].present?
      end
    end
    puts 'Laws loaded'
  end
end

namespace :import_annex_operators_csv do
  I18n.locale = :en
  desc 'Loads annex operators data from a csv file'
  task create_annex_operators: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'annex_operators.csv'))
    puts '* Annex operators... *'
    AnnexOperator.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country_names = data_row['countries'].split(',') if data_row['countries'].present?
        country_ids   = Country.where(name: country_names).pluck(:id)

        category_names = data_row['category_name'].split(',') if data_row['category_name'].present?
        category_ids   = Category.where(name: category_names).pluck(:id)

        data_ao = {}
        data_ao[:illegality]   = data_row['illegality']

        country_ids.each do |country_id|
          data_ao[:country_id] = country_id

          @ao = AnnexOperator.find_or_create_by!(data_ao)
          @ao.update!(illegality: data_row['illegality_fr'],
                      categorings_attributes: [{ category_id: category_ids.first, categorizable: @ao }],
                      severities_attributes: [{ level: 3, details: data_row['severity_3'] || 'Not specified' },
                                              { level: 2, details: data_row['severity_2'] || 'Not specified' },
                                              { level: 1, details: data_row['severity_1'] || 'Not specified' },
                                              { level: 0, details: data_row['severity_0'] || 'Not specified' }], locale: :fr)
        end
      end
    end
    puts 'Annex operators loaded'
  end
end

namespace :import_annex_governance_csv do
  I18n.locale = :en
  desc 'Loads annex governance data from a csv file'
  task create_annex_governance: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'annex_governance.csv'))
    puts '* Annex governance... *'
    AnnexGovernance.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        data_ag = {}
        data_ag[:governance_pillar]  = data_row['governance_pillar']
        data_ag[:governance_problem] = data_row['governance_problem']

        @ag = AnnexGovernance.find_or_create_by!(data_ag)
        @ag.update!(governance_problem: data_row['governance_problem_fr'],
                    severities_attributes: [{ level: 3, details: data_row['severity_3'] || 'Not specified' },
                                            { level: 2, details: data_row['severity_2'] || 'Not specified' },
                                            { level: 1, details: data_row['severity_1'] || 'Not specified' },
                                            { level: 0, details: data_row['severity_0'] || 'Not specified' }], locale: :fr)
      end
    end
    puts 'Annex governance loaded'
  end
end

namespace :import_operator_observations_csv do
  I18n.locale = :en
  desc 'Loads operator observations data from a csv file'
  task create_operator_observation: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'operator_observations.csv'))
    puts '* Operators observations... *'
    Observation.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country_names = data_row['countries'].split(',') if data_row['countries'].present?
        country_id    = Country.where(name: country_names).pluck(:id).first

        category_names = data_row['category_name'].split(',') if data_row['category_name'].present?
        category_ids   = Category.where(name: category_names).pluck(:id)

        monitor_name = data_row['monitor_name']
        monitor_id   = Observer.where(name: monitor_name).pluck(:id) if monitor_name.present?

        operator_name = data_row['operator_name']
        operator_id   = Operator.where(name: operator_name).pluck(:id) if operator_name.present?

        law_names = data_row['legal_reference'].split(',') if data_row['legal_reference'].present?
        law_ids = []
        if law_names.present?
          law_names.each do |law_name|
            law_ids << Law.where(legal_reference: law_name).first_or_create.id
          end
        end

        data_oo = {}
        data_oo[:observation_type]  = 'AnnexOperator'
        data_oo[:publication_date]  = data_row['publication_date']
        data_oo[:country_id]        = country_id
        data_oo[:details]           = data_row['description']
        data_oo[:evidence]          = data_row['evidence']
        data_oo[:concern_opinion]   = data_row['concern_opinion']
        data_oo[:litigation_status] = data_row['litigation_status']
        data_oo[:pv]                = data_row['pv']
        data_oo[:observer_id]       = monitor_id.first  if monitor_id.present?
        data_oo[:operator_id]       = operator_id.first if operator_id.present?

        @oo = Observation.find_or_create_by!(data_oo)

        data_ao = {}
        data_ao[:illegality] = data_row['illegality']
        data_ao[:law_ids]    = law_ids    if law_ids.present?
        data_ao[:country_id] = country_id if country_id.present?

        if @ao = AnnexOperator.find_by(illegality: data_row['illegality'])
          @ao.update!(law_ids: law_ids, country_id: country_id)
          @ao
        else
          @ao = AnnexOperator.create!(data_ao)
          @ao.update!(law_ids: law_ids,
                      categorings_attributes: [{ category_id: category_ids.first, categorizable: @ao }],
                      severities_attributes: [{ level: 3, details: 'Not specified' },
                                              { level: 2, details: 'Not specified' },
                                              { level: 1, details: 'Not specified' },
                                              { level: 0, details: 'Not specified' }])
        end

        severity_id = @ao.severities.where(level: data_row['severities']).first.id

        @oo.update!(annex_operator_id: @ao.id, severity_id: severity_id, documents_attributes: [{name: data_row['document_name'], document_type: 'Report'}])
      end
    end
    puts 'Operator observations loaded'
  end
end

namespace :import_governance_observations_csv do
  I18n.locale = :en
  desc 'Loads governance observations data from a csv file'
  task create_governance_observation: :environment do
    filename = File.expand_path(File.join(Rails.root, 'db', 'files', 'governance_observations.csv'))
    puts '* Governance observations... *'
    Observation.transaction do
      CSV.foreach(filename, col_sep: ';', row_sep: :auto, headers: true, encoding: 'UTF-8') do |row|
        data_row = row.to_h

        country_names = data_row['countries'].split(',') if data_row['countries'].present?
        country_id    = Country.where(name: country_names).pluck(:id).first

        monitor_name = data_row['monitor_name']
        monitor_id   = Observer.where(name: monitor_name).pluck(:id).first if monitor_name.present?

        operator_name = data_row['operator_name']
        operator_id   = Operator.where(name: operator_name, operator_type: 'Company').first_or_create.id if operator_name.present?

        species_name = data_row['species_name']
        species_id   = Species.where(name: species_name, common_name: data_row['species_common_name']).first_or_create.id if species_name.present?

        government_entity = data_row['government_entity']
        government_id     = Government.where(government_entity: government_entity, country_id: country_id).first_or_create.id if government_entity.present?

        data_go = {}
        data_go[:observation_type]  = 'AnnexGovernance'
        data_go[:publication_date]  = data_row['publication_date']
        data_go[:country_id]        = country_id
        data_go[:details]           = data_row['description']
        data_go[:evidence]          = data_row['evidence']
        data_go[:concern_opinion]   = data_row['concern_opinion']
        data_go[:observer_id]       = monitor_id    if monitor_id.present?
        data_go[:operator_id]       = operator_id   if operator_id.present?
        data_go[:government_id]     = government_id if government_id.present?

        @go = Observation.find_or_create_by!(data_go)

        data_ag = {}
        data_ag[:governance_pillar]  = data_row['governance_pillar']
        data_ag[:governance_problem] = data_row['governance_problem']

        if @ag = AnnexGovernance.find_by(governance_problem: data_row['governance_problem'])
          @ag
        else
          if data_ag['governance_pillar'].blank?
            data_ag['governance_pillar'] = 'Not specified'
          end
          @ag = AnnexGovernance.create!(data_ag)
          @ag.update!(governance_problem: data_row['governance_problem_fr'],
                      severities_attributes: [{ level: 3, details: 'Not specified' },
                                              { level: 2, details: 'Not specified' },
                                              { level: 1, details: 'Not specified' },
                                              { level: 0, details: 'Not specified' }], locale: :fr)
        end

        severity_id = @ag.severities.where(level: data_row['severities']).first.id

        @go.update!(annex_governance_id: @ag.id, severity_id: severity_id, species_ids: [species_id], documents_attributes: [{name: data_row['document_name'], document_type: 'Report'}])
      end
    end
    puts 'Governance observations loaded'
  end
end
