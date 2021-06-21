namespace :check do
  task document_files: :environment do
    doc_files =  DocumentFile.all
    od_doc_files = DocumentFile.where(id: OperatorDocument.unscoped.pluck(:document_file_id))
    odh_doc_files = DocumentFile.where(id: OperatorDocumentHistory.unscoped.pluck(:document_file_id))

    doc_files_orph = DocumentFile.where.not(id: (od_doc_files.pluck(:id) + odh_doc_files.pluck(:id)).uniq)

    puts "All document files: #{doc_files.count}"
    puts "Document files belongs to operator_document: #{od_doc_files.count}"
    puts "Document files belongs to operator_document_history: #{odh_doc_files.count}"
    puts "Orphaned Doc files: #{doc_files_orph.count}"

    doc_files_orph.each do |doc|
      puts "Orphaned doc has paper trail history #{doc.id}" if PaperTrail::Version.where(item_type: 'OperatorDocument').where_object(document_file_id: doc.id).any?
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

  task operator_approved: :environment do
    Operator.find_each do |operator|
      next unless operator.operator_documents.signature.any?

      valid_approved_status = operator.operator_documents.signature.approved.any?

      next if valid_approved_status == operator.approved?

      active_or_not = operator.is_active? ? 'ACTIVE' : 'NOT_ACTIVE'

      puts "BAD DATA for #{active_or_not} , FA: #{operator.fa_id.present?} operator #{operator.id} - #{operator.name} - approved should be #{valid_approved_status} but is #{operator.approved?}"
    end
  end
end
