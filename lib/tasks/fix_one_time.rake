namespace :fix_one_time do
  desc 'Remove couple not provided docs'
  task remove_mismatched_docs: :environment do
    for_real = ENV['FOR_REAL'] == 'true'
    docs_to_remove = [22791, 22792, 22797, 22798, 22799, 22800, 22808, 22809, 22810, 23751, 23759]

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    puts "This script will remove #{docs_to_remove.count} documents"

    ActiveRecord::Base.transaction do
      docs = OperatorDocument.unscoped.where(id: docs_to_remove)
      histories = OperatorDocumentHistory.unscoped.where(operator_document_id: docs_to_remove)
      versions = PaperTrail::Version.where(item: docs)

      files = DocumentFile.where(id: docs.pluck(:document_file_id) + histories.pluck(:document_file_id))
      if for_real
        files.each do |file|
          puts "Removing file #{file.id}"
          file.really_destroy!
        end
      else
        puts "Removing files... #{files.delete_all} affected"
      end

      annexes = OperatorDocumentAnnex.where(id: AnnexDocument
                                            .where(documentable: histories)
                                            .or(AnnexDocument.where(documentable: docs))
                                            .pluck(:operator_document_annex_id)
                                           )

      if for_real
        annexes.each do |annex|
          puts "Removing annex #{annex.id}"
          annex.really_destroy!
        end
      else
        puts "Removing annexes... #{annexes.delete_all} affected"
      end

      puts "Removing versions... #{versions.delete_all} affected"
      puts "Removing histories... #{histories.delete_all} affected"
      puts "Removing docs... #{docs.delete_all} affected"

      raise ActiveRecord::Rollback unless for_real
    end
  end
end
