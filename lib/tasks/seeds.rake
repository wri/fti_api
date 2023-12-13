namespace :seeds do
  task generate_fixtures: :environment do
    generate_for_model "Country"
    generate_for_model "AboutPageEntry"
    generate_for_model "Page", locale: %w[en fr]
    generate_for_model "Tool"
    generate_for_model "Tutorial"
    generate_for_model "HowTo"
    generate_for_model "Donor"
    generate_for_model "Partner"
    generate_for_model "Faq"

    generate_for_model "Law"
    generate_for_model "Government"
    generate_for_model "Category"
    generate_for_model "Subcategory"
    generate_for_model "Severity"

    generate_for_model "RequiredOperatorDocumentGroup"
    generate_for_model "RequiredOperatorDocument"

    holding_names = ["Groupe Vicwood Thanry"]
    holdings = Holding.where(name: holding_names)
    holding_operators = Operator.where(holding: holdings).pluck(:slug)

    # observations
    monitor_names = %w[
      OGF PAPEL FODER CADDE ECODEV CAGDF RENOI OCEAN AGRECO
    ]
    observers = Observer.where(name: monitor_names)
    reports = ObservationReport.joins(:observers).where(observers: observers).distinct
    observations = Observation.published.where(observation_report: reports)
    observation_operators = observations.pluck(:operator_id).uniq

    operator_slugs = %w[
      ifo-interholco cfc sifco lorema siencam
      cib cft mokabi-sa afriwood-industries
    ].concat(holding_operators).concat(observation_operators).uniq
    operators = Operator.where(slug: operator_slugs)
    fmu_operators = FmuOperator.where(operator: operators)
    fmus = Fmu.where(id: fmu_operators.pluck(:fmu_id))
    generate_for_model "Holding", entries: holdings
    generate_for_model "Operator", entries: operators
    generate_for_model "FmuOperator", entries: fmu_operators
    generate_for_model "Fmu", entries: fmus

    # documents
    documents = OperatorDocument.where(operator: operators).where(fmu: [nil, fmus])
    document_history = OperatorDocumentHistory.where(operator_document: documents).where(fmu: [nil, fmus])
    document_files = DocumentFile.where(id: documents.pluck(:document_file_id).concat(document_history.pluck(:document_file_id)).uniq)
    generate_for_model "DocumentFile", entries: document_files
    generate_for_model "OperatorDocument", entries: documents, exclude: %w[user_id], anonymize: %w[note]
    generate_for_model "OperatorDocumentHistory", entries: document_history, exclude: %w[user_id]

    # monitors
    evidences = ObservationDocument.where(observation: observations)
    generate_for_model "Observer", entries: observers
    generate_for_model "ObservationReport", entries: reports
    generate_for_model "Observation", entries: observations, exclude: %w[user_id modified_user_id], anonymize: %w[admin_comment monitor_comment]
    generate_for_model "ObservationDocument", entries: evidences, exclude: %w[user_id]
  end

  def generate_for_model(model_class, entries: nil, exclude: [], locale: nil, anonymize: [])
    model = model_class.constantize
    puts "Dumping fixtures for: #{model_class}"

    increment = 1

    model_file_name = "#{Rails.root}/db/fixtures/#{model_class.underscore.pluralize}.yml"
    model_file = File.open(model_file_name, "w")

    translated_attributes = model.respond_to?(:translated_attribute_names) ? model.translated_attribute_names : []

    entries ||= model.order(id: :asc).all

    if translated_attributes.any?
      translation_dir = "#{Rails.root}/db/fixtures/#{model_class.underscore}"
      Dir.mkdir(translation_dir) unless Dir.exist?(translation_dir)

      translation_file_name = "#{translation_dir}/translations.yml"
      translation_file = File.open(translation_file_name, "w")
      entries = entries.includes(:translations)
    end

    exclude_attributes = exclude.concat(%w[created_at updated_at])

    entries.each do |entry|
      attrs = entry.attributes
      attrs.delete_if { |k, _v| translated_attributes.include?(k.to_sym) }
      attrs.delete_if { |k, _v| exclude_attributes.include?(k) }
      attrs.each { |k, _v| attrs[k] = "Lorem ipsum for #{k}" if anonymize.include?(k) } if anonymize.any?
      attrs.compact_blank!

      key = model_class + "_" + increment.to_s
      output = {key => attrs}
      model_file << output.to_yaml.gsub(/^---/, "")

      if translated_attributes.any?
        entry.translations.each do |t|
          next if locale.present? && locale.exclude?(t.locale)

          attrs = t.attributes
          attrs.delete_if { |k, _v| exclude_attributes.include?(k) }
          attrs.each { |k, _v| attrs[k] = "Lorem ipsum for #{k}" if anonymize.include?(k) } if anonymize.any?
          translation_key =  "#{key}_#{t.locale}_translation"
          translation_output = {translation_key => attrs}.compact_blank
          translation_file << translation_output.to_yaml.gsub(/^---/, "")
        end
      end

      increment += 1
    end
    model_file.close
    translation_file.close if translated_attributes.any?
  end
end
