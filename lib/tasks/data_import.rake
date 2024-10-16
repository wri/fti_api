require "csv"
require "http"

namespace :import do
  I18n.locale = :en

  # This task is not to be used in the import
  desc "Create Operator Documents"
  task operator_documents: :environment do
    puts "* Operator documents"

    puts "... creating required operator documents per country"
    Operator.find_each do |operator|
      country = RequiredOperatorDocumentCountry.where(country_id: operator.country_id).any? ? operator.country_id : nil
      RequiredOperatorDocumentCountry.where(country_id: country).find_each do |rodc|
        OperatorDocumentCountry.where(required_operator_document_id: rodc.id, operator_id: operator.id).first_or_create
      end
    end

    puts "... creating required operator documents per fmu"
    Fmu.find_each do |fmu|
      country = RequiredOperatorDocumentFmu.where(country_id: fmu.country_id).any? ? fmu.country_id : nil
      RequiredOperatorDocumentFmu.where(country_id: country).find_each do |rodf|
        if fmu.operator_id.present?
          OperatorDocumentFmu.where(required_operator_document_id: rodf.id, operator_id: fmu.operator_id, fmu_id: fmu.id).first_or_create
        end
      end
    end
    puts "Finished operator documents"
  end

  desc "Loads protected areas from GFW data API"
  task protected_areas: :environment do
    countries = if ENV["COUNTRIES"]
      Country.where(iso: ENV["COUNTRIES"].split(","))
    else
      Country.active
    end

    abort "No counties found" if countries.empty?

    countries_iso_string = countries.pluck(:iso).uniq.map { |iso| "'#{iso}'" }.join(", ")
    sql = "SELECT wdpa_pid, name, gfw_geojson, iso3 FROM data where marine = '0' and iso3 IN (#{countries_iso_string})"

    ProtectedArea.where(country: countries).delete_all
    ProtectedArea.delete_all if ENV["CLEAR_ALL"]

    response = HTTP.post(
      "https://data-api.globalforestwatch.org/dataset/wdpa_protected_areas/v202302/query/json",
      json: {sql: sql}
    )
    response_json = JSON.parse(response.body)
    response_json["data"].each do |protected_area|
      country = Country.find_by(iso: protected_area["iso3"])
      ProtectedArea.create!(
        name: protected_area["name"],
        geojson: protected_area["gfw_geojson"],
        wdpa_pid: protected_area["wdpa_pid"],
        country: country
      )
      puts "Country #{country.name} protected area #{protected_area["name"]} imported"
    end
  end
end
