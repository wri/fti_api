namespace :documents do
  desc "Removing documents completely"
  task remove: :environment do
    for_real = ENV["FOR_REAL"] == "true"
    docs_to_remove = (ENV["DOCS"] || "").split(",")
    files_to_remove = (ENV["FILES"] || "").split(",")

    abort "Please provide documents (DOCS) to remove or files (FILES)" if docs_to_remove.empty? && files_to_remove.empty?
    abort "You should provide either DOCS or FILES" if docs_to_remove.any? && files_to_remove.any?

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    if docs_to_remove.any?
      puts "This script will remove #{docs_to_remove.count} documents"
    end

    if files_to_remove.any?
      puts "This script will remove #{files_to_remove.count} files with associated operator documents and histories"
    end

    ActiveRecord::Base.transaction do
      docs = if docs_to_remove.any?
        OperatorDocument.unscoped.where(id: docs_to_remove)
      else
        OperatorDocument.unscoped.where(document_file_id: files_to_remove)
      end
      histories = if docs_to_remove.any?
        OperatorDocumentHistory.unscoped.where(operator_document_id: docs_to_remove)
      else
        OperatorDocumentHistory.unscoped.where(document_file_id: files_to_remove).or(
          OperatorDocumentHistory.unscoped.where(operator_document_id: docs)
        )
      end
      operator_ids = (docs.pluck(:operator_id) + histories.pluck(:operator_id)).uniq
      versions = PaperTrail::Version.where(item: docs)
      if files_to_remove.any?
        versions_with_document_id = files_to_remove.map { |id| "object LIKE '%document_file_id: #{id.to_i}%'" }.join(" OR ")
        versions = versions.or(PaperTrail::Version.where(item_type: "OperatorDocument").where(versions_with_document_id))
      end

      files = DocumentFile.where(id: docs.pluck(:document_file_id) + histories.pluck(:document_file_id))
      if for_real
        files.each do |file|
          puts "Removing file #{file.id}"
          file.destroy!
        end
      else
        puts "Removing files... #{files.delete_all} affected"
      end

      annexes = OperatorDocumentAnnex.where(id: AnnexDocument
                                            .where(documentable: histories)
                                            .or(AnnexDocument.where(documentable: docs))
                                            .select(:operator_document_annex_id))

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

      if operator_ids.any?
        puts "Syncing scores..."
        puts "Only for operators: #{operator_ids.join(", ")}"
        SyncTasks.new(as_rake_task: false).sync_scores(operator_id: operator_ids)
        puts "Refreshing ranking..."
        RankingOperatorDocument.refresh
      end

      raise ActiveRecord::Rollback unless for_real
    end
  end
end
