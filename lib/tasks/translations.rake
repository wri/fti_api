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
      Faq,
      Fmu,
      Government,
      HowTo,
      Observation,
      Observer,
      Operator,
      RequiredGovDocument,
      RequiredGovDocumentGroup,
      RequiredOperatorDocument,
      RequiredOperatorDocumentGroup,
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
end
