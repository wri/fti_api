namespace :check do
  task document_files: :environment do
    doc_files = DocumentFile.all
    od_doc_files = DocumentFile.where(id: OperatorDocument.unscoped.select(:document_file_id))
    odh_doc_files = DocumentFile.where(id: OperatorDocumentHistory.unscoped.select(:document_file_id))

    doc_files_orph = DocumentFile.where.not(id: (od_doc_files.pluck(:id) + odh_doc_files.pluck(:id)).uniq)

    puts "All document files: #{doc_files.count}"
    puts "Document files belongs to operator_document: #{od_doc_files.count}"
    puts "Document files belongs to operator_document_history: #{odh_doc_files.count}"
    puts "Orphaned Doc files: #{doc_files_orph.count}"

    doc_files_orph.each do |doc|
      puts "Orphaned doc has paper trail history #{doc.id}" if PaperTrail::Version.where(item_type: "OperatorDocument").where_object(document_file_id: doc.id).any?
    end
  end

  task fmu_docs: :environment do
    RequiredOperatorDocumentFmu.find_each do |rodf|
      FmuOperator.where(fmu: rodf.fmus).find_each do |fo|
        puts "Operator #{fo.operator_id} does not have required doc #{rodf.id}}" unless OperatorDocument.where(required_operator_document: rodf, operator_id: fo.operator_id)
      end
    end
  end

  task country_docs: :environment do
    RequiredOperatorDocumentCountry.find_each do |rodc|
      Operator.where(country: rodc.country).pluck(:operator_id).each do |id|
        puts "Operator #{id} does not have required doc #{rodc.id}" unless OperatorDocument.where(required_operator_document: rodc, operator_id: id)
      end
    end
  end

  # FMU documents exist only for FMUs whose forest type is listed in the required document forest types
  # (empty list means all types), the same rule FmuOperator#update_documents_list creates and destroys them by.
  # Reports documents breaking that rule and documents the rule says should exist but do not.
  # VERBOSE=true adds paper trail hints about where a wrong document came from.
  task docs_forest_type_mismatch: :environment do
    mismatched = OperatorDocumentFmu
      .joins(:fmu, :required_operator_document)
      .where("cardinality(required_operator_documents.forest_types) > 0")
      .where("NOT (fmus.forest_type = ANY (required_operator_documents.forest_types))")
      .includes(:fmu, :required_operator_document, operator: :country)
      .order("fmus.forest_type", :fmu_id, :id)
      .to_a

    puts "== Documents for a wrong forest type =="
    mismatched.each do |od|
      fmu = od.fmu
      rod = od.required_operator_document
      expected_forest_types = rod.forest_types.join(", ")

      puts "Document id: #{od.id} - status: #{od.status}, last updated at: #{od.updated_at}, operator: #{od.operator.name} (id: #{od.operator.id}), Country: #{od.operator.country&.name}, FMU: #{fmu.name} (id: #{fmu.id}) forest type: #{fmu.forest_type} but required document #{rod.id} is for forest types: #{expected_forest_types}"

      if ENV["VERBOSE"]
        # older versions store forest_type as the enum name, newer ones as the integer
        fmu_versions_forest_types = fmu.versions.filter_map { |v| v.object&.dig("forest_type") }.map { it.is_a?(Integer) ? Fmu.forest_types.key(it) : it }
        fmu_any_version_with_forest_type = rod.forest_types.intersect?(fmu_versions_forest_types)
        puts "======> Document versions: #{od.versions.count}"
        puts "======> FMU: #{fmu.id}, versions: #{fmu.versions.count}, any version with any of #{expected_forest_types} type: #{fmu_any_version_with_forest_type}"
      end
    end

    puts
    puts "== Missing documents =="
    active_country_ids = Country.active.ids
    required_documents = RequiredOperatorDocumentFmu.order(:id).group_by(&:country_id)
    existing = OperatorDocumentFmu.pluck(:fmu_id, :operator_id, :required_operator_document_id).to_set
    missing_count = 0

    Fmu.joins(:operator).includes(:operator).where.not(operators: {fa_id: [nil, ""]}).order(:id).each do |fmu|
      # FMUs in non-active countries use the generic required documents (country_id is null)
      documents_country_id = active_country_ids.include?(fmu.country_id) ? fmu.country_id : nil

      required_documents.fetch(documents_country_id, []).each do |rod|
        next unless rod.applies_to_forest_type?(fmu.forest_type)
        next if existing.include?([fmu.id, fmu.operator.id, rod.id])

        missing_count += 1
        puts "FMU: #{fmu.name} (id: #{fmu.id}) forest type: #{fmu.forest_type}, operator: #{fmu.operator.name} (id: #{fmu.operator.id}) has no document for required document #{rod.id} (forest types: #{rod.forest_types.join(", ").presence || "all"})"
      end
    end

    without_fmu = OperatorDocumentFmu.where.not(fmu_id: Fmu.select(:id)).or(OperatorDocumentFmu.where(fmu_id: nil))

    puts
    puts "== Summary =="
    puts "FMU documents: #{OperatorDocumentFmu.count}"
    puts "Wrong forest type: #{mismatched.size}"
    mismatched.group_by { it.fmu.forest_type }.each do |forest_type, documents|
      puts "  FMU forest type #{forest_type}: #{documents.size} documents, #{documents.map(&:fmu_id).uniq.size} FMUs"
    end
    puts "Missing: #{missing_count}"
    puts "Without FMU, not checked: #{without_fmu.count} #{without_fmu.ids.inspect}"
  end

  task operator_approved: :environment do
    Operator.find_each do |operator|
      next unless operator.operator_documents.signature.any?

      valid_approved_status = operator.operator_documents.signature.approved.any?

      next if valid_approved_status == operator.approved?

      active_or_not = operator.is_active? ? "ACTIVE" : "NOT_ACTIVE"

      puts "BAD DATA for #{active_or_not} , FA: #{operator.fa_id.present?} operator #{operator.id} - #{operator.name} - approved should be #{valid_approved_status} but is #{operator.approved?}"
    end
  end
end
