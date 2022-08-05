require 'countries/iso3166'

namespace :countries do
  desc 'Update existing country translations using countries gem'
  task update_translations: :environment do
    for_real = ENV['FOR_REAL'] == 'true'
    puts "DRY RUN" unless for_real

    Country.find_each do |country|
      (I18n.available_locales - [:en]).map do |locale|
        I18n.with_locale(locale) do
          country_metadata = ISO3166::Country.find_country_by_alpha3(country.iso)
          if country_metadata.nil?
            puts "ERROR: no country metadata for #{country.iso}"
            next
          end

          new_name = country_metadata.translation(locale)
          puts "locale: #{locale} updating #{country.iso} name: #{country.name} to: #{new_name}"
          country.update!(name: new_name) if for_real
        end
      end
    end
  end
end
