require "benchmark"
namespace :translations do
  desc "Will remove duplicated translations"
  task find_duplicates: :environment do
    translation_tables = ActiveRecord::Base.connection.tables.select { |table_name| table_name.ends_with?("_translations") }

    translation_tables.each do |translation_table|
      model_table = translation_table.gsub("_translations", "")
      model_id = model_table.singularize + "_id"
      query = <<~SQL
        SELECT DISTINCT #{model_id}
        FROM #{translation_table}
        group by #{model_id}, locale
        having count(*) > 1
        order by #{model_id}
      SQL

      puts ActiveRecord::Base.connection.execute(query).to_a
    end
  end

  task create_spanish_fallback: :environment do
    Rake::Task["translations:create_fallback"].invoke(:es)
  end

  task create_portuguese_fallback: :environment do
    Rake::Task["translations:create_fallback"].invoke(:pt)
  end

  task :create_fallback, [:language] => :environment do |_, args|
    locale = args[:language]
    default_locale = I18n.default_locale

    models = [
      AboutPageEntry,
      Category,
      Contributor,
      Country,
      CountryLink,
      CountryVpa,
      Country,
      Faq,
      Government,
      HowTo,
      Newsletter,
      Observation,
      Page,
      RequiredGovDocumentGroup,
      RequiredGovDocument,
      RequiredOperatorDocumentGroup,
      RequiredOperatorDocument,
      Severity,
      Species,
      Subcategory,
      Tool,
      Tutorial
    ]

    puts "Creating fallbacks for #{locale} language using #{default_locale} as default locale"

    ActiveRecord::Base.transaction do
      models.each do |model|
        translation_model = model.translation_class
        translation_table = translation_model.table_name
        foreign_key = "#{model.model_name.singular}_id"
        attributes = model.translated_attribute_names

        query = <<~SQL
          INSERT INTO #{translation_table} (#{foreign_key}, locale, #{attributes.join(", ")}, created_at, updated_at)
            SELECT #{foreign_key}, '#{locale}', #{attributes.join(", ")}, NOW(), NOW()
            FROM #{translation_table} t1
            WHERE locale = '#{default_locale}' AND NOT EXISTS (
              SELECT * from #{translation_table} WHERE locale = '#{locale}' AND #{foreign_key} = t1.#{foreign_key}
            )
        SQL

        puts "Creating fallbacks for #{model.name}..."
        ActiveRecord::Base.connection.execute(query)
      end
    end

    puts "All done"
  end

  task prepare_csv: :environment do
    translate_from = ENV["TRANSLATE_FROM"] || I18n.default_locale.to_s

    models = [
      AboutPageEntry,
      Category,
      Contributor,
      Country,
      CountryLink,
      CountryVpa,
      Country,
      Faq,
      Government,
      HowTo,
      Newsletter,
      Observation,
      Page,
      RequiredGovDocumentGroup,
      RequiredGovDocument,
      RequiredOperatorDocumentGroup,
      RequiredOperatorDocument,
      Severity,
      Species,
      Subcategory,
      Tool,
      Tutorial
    ]
    models = ENV["MODELS"].split(",").map(&:constantize) if ENV["MODELS"].present?

    CSV.open("tmp/translations.csv", "w") do |csv|
      csv << ["model", "id", "locale", "attribute", "value"]

      models.each do |model|
        translation_model = model.translation_class
        translation_table = translation_model.table_name
        foreign_key = "#{model.model_name.singular}_id"
        attributes = model.translated_attribute_names

        query = <<~SQL
          SELECT #{foreign_key}, locale, #{attributes.join(", ")}
          FROM #{translation_table}
          WHERE locale = '#{translate_from}'
        SQL

        puts "Fetching translations for #{model.name}..."
        ActiveRecord::Base.connection.execute(query).each do |row|
          attributes.map(&:to_s).each do |attribute|
            value = row[attribute]
            next if value.blank?

            csv << [model.name, row[foreign_key], row["locale"], attribute, value]
          end
        end
      end
    end
  end

  task load_from_csv: :environment do
    csv_file = ENV["CSV_FILE"] || "tmp/translations.csv"

    puts "Loading translations from #{csv_file}"

    CSV.foreach(csv_file, headers: true) do |row|
      model_name = row["model"].constantize
      model_id = row["id"].to_i
      locale = row["locale"]
      attribute = row["attribute"]
      value = row["value"]

      translation = model_name.translation_class.find_by(
        "#{model_name.model_name.singular}_id": model_id,
        locale: locale
      )

      # fallback translation should be there (create_fallback task), so this is edge case meaning that probably record does not exist
      if translation.nil?
        puts "Translation not found for #{model_name.name} with ID #{model_id} and locale #{locale}."
        next
      end

      translation[attribute] = value
      translation.save!
    end

    puts "Translations loaded successfully"
  end
end
