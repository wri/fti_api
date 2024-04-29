class SeedsTasks
  include Rake::DSL

  HOLDINGS = ["Groupe Vicwood Thanry"]
  MONITORS = %w[OGF PAPEL FODER CADDE ECODEV CAGDF RENOI OCEAN AGRECO]
  OPERATORS = %w[ifo-interholco cfc sifco lorema siencam cib cft mokabi-sa afriwood-industries]
  EXTRA_FMUS = %w[08-003 08-005 08-009]

  DATE_FIELDS = %w[created_at updated_at deleted_at operator_document_updated_at operator_document_created_at publication_date response_date]

  def initialize
    namespace :seeds do
      desc "Generate fixtures to use as development or e2e database. First run db:restore_from_file or db:restore_from_server to get latest data from production."
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

        holdings = Holding.where(name: HOLDINGS)
        holding_operators = Operator.where(holding: holdings).pluck(:slug)

        # observations
        observers = Observer.where(name: MONITORS).order(:id)
        reports = ObservationReport.joins(:observers).where(observers: observers).distinct.order(:id)
        observations = Observation.published.where(observation_report: reports).order(:id)

        operator_slugs = OPERATORS.concat(holding_operators).uniq
        operators = Operator.where(slug: operator_slugs).order(:id)
        fmu_operators = FmuOperator.where(operator: operators).order(:id)
        fmus = Fmu.where(id: fmu_operators.pluck(:fmu_id)).or(Fmu.where(id: Fmu.where(name: EXTRA_FMUS))).order(:id)
        observations = observations.where(fmu: [nil, fmus]) # only observations with existing fmu or no fmu
        observations = observations.where(operator: [nil, operators]).order(:id)
        generate_for_model "Holding", entries: holdings
        generate_for_model "Operator", entries: operators
        generate_for_model "FmuOperator", entries: fmu_operators
        generate_for_model "Fmu", entries: fmus, exclude: %w[geometry created_at updated_at]

        # documents
        documents = OperatorDocument.where(operator: operators).where(fmu: [nil, fmus]).order(:id)
        document_history = OperatorDocumentHistory.where(operator_document: documents).where(fmu: [nil, fmus]).order(:id)
        document_files = DocumentFile.where(id: documents.pluck(:document_file_id).concat(document_history.pluck(:document_file_id)).uniq).order(:id)
        annex_documents = AnnexDocument
          .where(documentable: documents)
          .or(AnnexDocument.where(documentable: document_history))
          .where(operator_document_annex: OperatorDocumentAnnex.all)
          .order(:id)
        annexes = OperatorDocumentAnnex.where(id: annex_documents.pluck(:operator_document_annex_id).uniq).order(:id)
        generate_for_model "DocumentFile", entries: document_files
        generate_for_model "OperatorDocument", entries: documents, exclude: %w[user_id], anonymize: %w[note]
        generate_for_model "OperatorDocumentHistory", entries: document_history, exclude: %w[user_id]
        generate_for_model "AnnexDocument", entries: annex_documents
        generate_for_model "OperatorDocumentAnnex", entries: annexes, exclude: %w[user_id]

        # monitors
        evidences = ObservationDocument.joins(:observations).where(observations: observations).order(:id)
        report_observers = ObservationReportObserver.where(observation_report: reports, observer: observers).order(:id)
        observer_observations = ObserverObservation.where(observation: observations, observer: observers).order(:id)
        countries_observers = CountriesObserver.where(observer: observers).order(:country_id, :observer_id)
        governments_observations = GovernmentsObservation.where(observation: observations).order(:id)
        observation_operators = ObservationOperator.where(observation: observations, operator: operators).order(:id)
        documents_observations = ObservationDocumentsObservation.where(observation: observations, observation_document: evidences).order(:observation_id, :observation_document_id)
        generate_for_model "Observer", entries: observers, exclude: %w[responsible_admin_id]
        generate_for_model "CountriesObserver", entries: countries_observers, exclude: %w[created_at updated_at]
        generate_for_model "ObservationReport", entries: reports, exclude: %w[created_at updated_at user_id]
        generate_for_model "ObservationReportObserver", entries: report_observers, exclude: %w[created_at updated_at]
        generate_for_model "Observation", entries: observations, locale: %w[en], exclude: %w[created_at updated_at user_id modified_user_id], anonymize: %w[admin_comment monitor_comment]
        generate_for_model "ObservationDocument", entries: evidences, exclude: %w[created_at updated_at user_id]
        generate_for_model "ObserverObservation", entries: observer_observations, exclude: %w[created_at updated_at]
        generate_for_model "GovernmentsObservation", entries: governments_observations, exclude: %w[created_at updated_at]
        generate_for_model "ObservationOperator", entries: observation_operators, exclude: %w[created_at updated_at]
        generate_for_model "ObservationDocumentsObservation", entries: documents_observations, exclude: %w[created_at updated_at]
      end
    end
  end

  def generate_for_model(model_class, entries: nil, exclude: %w[created_at updated_at], locale: [], anonymize: [])
    model = model_class.constantize
    puts "Dumping fixtures for: #{model_class}"

    model_file_name = "#{Rails.root}/db/fixtures/#{model_class.underscore.pluralize}.yml"
    model_file = File.open(model_file_name, "w")

    translated_attributes = model.respond_to?(:translated_attribute_names) ? model.translated_attribute_names.map(&:to_s) : []

    entries ||= model.attribute_names.include?("id") ? model.order(id: :asc).all : model.all

    if translated_attributes.any?
      translation_dir = "#{Rails.root}/db/fixtures/#{model_class.underscore}"
      Dir.mkdir(translation_dir) unless Dir.exist?(translation_dir)

      translation_file_name = "#{translation_dir}/translations.yml"
      translation_file = File.open(translation_file_name, "w")
      entries = entries.includes(:translations)
    end

    exclude_attributes = exclude || []
    increment = 1

    entries.each do |entry|
      attrs = entry.attributes.except(*(exclude_attributes + translated_attributes))
      attrs.each { |k, _v| attrs[k] = "Lorem ipsum for #{k}" if anonymize.include?(k) } if anonymize.any?
      attrs.each { |k, _v| attrs[k] = attrs[k].to_s if DATE_FIELDS.include?(k) }
      attrs.compact_blank!

      key = "#{model_class}_#{entry.id || increment}"
      output = {key => attrs}
      model_file << output.to_yaml.gsub(/^---/, "").gsub(/^\.\.\./, "")

      if translated_attributes.any?
        entry.translations.each do |t|
          next if locale.any? && locale.exclude?(t.locale.to_s)

          attrs = t.attributes.except(*(["id"] + exclude_attributes))
          attrs.each { |k, _v| attrs[k] = "Lorem ipsum for #{k}" if anonymize.include?(k) } if anonymize.any?
          attrs.each { |k, _v| attrs[k] = attrs[k].to_s if DATE_FIELDS.include?(k) }
          attrs.compact_blank!
          translation_key = "#{key}_#{t.locale}_translation"
          translation_output = {translation_key => attrs}.compact_blank
          translation_file << translation_output.to_yaml.gsub(/^---/, "").gsub(/^\.\.\./, "")
        end
      end

      increment += 1
    end
    model_file.close
    translation_file.close if translated_attributes.any?
  end
end

SeedsTasks.new
