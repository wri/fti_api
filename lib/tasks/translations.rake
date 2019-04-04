require 'benchmark'
namespace :translations do

  desc 'Translates all fields to chinese'
  task chinese: :environment do
    Rake::Task['translations:all'].invoke(:'zh-CN')
  end

  desc 'Translates all fields to french'
  task french: :environment do
    Rake::Task['translations:all'].invoke(:fr)
  end

  desc 'Translates all fields'
  task :all, [:language] => :environment do |_, args|
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to translate to #{args[:language]} at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms do
      Category.find_each do |o|
        I18n.locale =  args[:language]
        if o.name.blank?
          I18n.locale = :en
          name = o.name
          I18n.locale = args[:language]
          o.update!(name: name)
        end
      end
      puts 'Finished Category'

      Country.find_each do |o|
        I18n.locale =  :fr
        if o.name.blank?
          I18n.locale = :en
          name = o.name
          region = o.region_name
          I18n.locale = args[:language]
          o.update!(name: name, region_name: region)
        end
      end
      puts 'Finished Country'

      Fmu.find_each do |o|
        I18n.locale =  args[:language]
        if o.name.blank?
          I18n.locale = :en
          name = o.name
          I18n.locale = args[:language]
          o.update!(name: name)
        end
      end
      puts 'Finished Fmu'

      Government.find_each do |o|
        I18n.locale =  args[:language]
        if o.government_entity.blank?
          I18n.locale = :en
          entity = o.government_entity
          details = o.details
          I18n.locale = args[:language]
          o.update!(government_entity: entity, details: details)
        end
      end
      puts 'Finished Government'

      Operator.find_each do |o|
        I18n.locale =  args[:language]
        if o.name.blank?
          I18n.locale = :en
          details = o.details
          name = o.name
          I18n.locale = args[:language]
          o.update!(details: details, name: name)
        end
      end
      puts 'Finished Operator'

      Observation.find_each do |o|
        I18n.locale =  args[:language]
        if o.details.blank?
          I18n.locale = :en
          details = o.details
          evidence = o.evidence
          opinion = o.concern_opinion
          status = o.litigation_status
          I18n.locale = args[:language]
          o.update!(details: details, evidence: evidence, concern_opinion: opinion, litigation_status: status)
        end
      end
      puts 'Finished Observation'

      Observer.find_each do |o|
        I18n.locale =  args[:language]
        if o.name.blank?
          I18n.locale = :en
          name = o.name
          organization = o.organization
          I18n.locale = args[:language]
          o.update!(name: name, organization: organization)
        end
      end
      puts 'Finished Observer'

      Partner.find_each do |o|
        I18n.locale =  args[:language]
        if o.name.blank?
          I18n.locale = :en
          name = o.name
          description = o.description
          I18n.locale = args[:language]
          o.update!(name: name, description: description)
        end
      end
      puts 'Finished Partner'

      RequiredOperatorDocumentGroup.find_each do |o|
        I18n.locale =  args[:language]
        if o.name.blank?
          I18n.locale = :en
          name = o.name
          I18n.locale = args[:language]
          o.update!(name: name)
        end
      end
      puts 'Finished RequiredOperatorDocumentGroup'

      Severity.find_each do |o|
        I18n.locale =  args[:language]
        if o.details.blank?
          I18n.locale = :en
          details = o.details
          I18n.locale = args[:language]
          o.update!(details: details)
        end
      end
      puts 'Finished Severity'

      Species.find_each do |o|
        I18n.locale =  args[:language]
        if o.common_name.blank?
          I18n.locale = :en
          common_name = o.common_name
          I18n.locale = args[:language]
          o.update!(common_name: common_name)
        end
      end
      puts 'Finished Species'

      Subcategory.find_each do |o|
        I18n.locale =  args[:language]
        if o.name.blank?
          I18n.locale = :en
          name = o.name
          details = o.details
          I18n.locale = args[:language]
          o.update!(name: name, details: details)
        end
      end
      puts 'Finished Partner'

      # Subcategory # name, details

    end
    Rails.logger.info "Translated to #{args[:language]}. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end
end