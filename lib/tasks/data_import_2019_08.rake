require 'csv'

namespace :import do
  namespace :v201908 do
    I18n.locale = :en

    desc 'Load geojson'
    task geojson: :environment do
      Rails.logger.info('Importing the geojson')
      new_fmus = []
      fmus = []
      old_fmus = []
      new_associations = []
      filename = File.expand_path(File.join(Rails.root, 'db', 'files', '2019-08', 'test.json'))
      file = File.read filename
      data_hash = JSON.parse(file)
      data_hash['features'].each do |row|
        #geometry['coordinates']
        properties = row['properties']
        name = properties['fmu_name'].strip
        country = Country.find_by(iso: properties['iso3_fmu'])
        operator = Operator.find_by(name: properties['company_na'])

        next unless name.present?

        fmus << name
        fmu = Fmu.where(name: name).first
        new_fmus << name unless fmu

        next unless operator && fmu

        new_associations << { "#{name}": operator.name} unless fmu.operator == operator
      end

      old_fmus = Fmu.all.select {|f| !fmus.include?(f.name)}

      puts "New fmus: #{new_fmus}"
      puts "Old fmus: #{old_fmus.map(&:name)}"
      puts "New associations: #{new_associations}"
    end
  end
end