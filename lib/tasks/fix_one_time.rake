namespace :fix_one_time do
  desc 'Fix translation duplications 08.2021'
  task translation_duplicates: :environment do
    for_real = ENV['FOR_REAL'] == 'true'

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real
    # this is one time script to fix translation duplications
    # First time I ran the scripts that removed only duplicates that had same values
    # using that kind of script

    # delete from operator_translations a
    #   using operator_translations b
    # where a.updated_at < b.updated_at
    # and a.operator_id = b.operator_id
    # and a.locale = b.locale
    # and coalesce(a.name, '') = coalesce(b.name, '')
    # and coalesce(a.details, '') = coalesce(b.details, '')

    # after that this list of potentially problematic entities left
    # {"fmu_id"=>46}
    # {"fmu_id"=>47}
    # {"fmu_id"=>49}
    # {"fmu_id"=>92}
    # {"observer_id"=>1}
    # {"observer_id"=>8}
    # {"operator_id"=>179}
    # {"operator_id"=>197}
    # {"operator_id"=>10589}
    # {"operator_id"=>10604}
    # {"operator_id"=>10615}
    # {"operator_id"=>100090}
    # {"operator_id"=>100091}
    # {"operator_id"=>100115}
    # {"operator_id"=>100151}
    # {"operator_id"=>120128}
    # {"operator_id"=>120133}
    # easier to keep the last updated_at translation value and remove the rest, then
    # check all problematic entities manually in active admin to see if everything is fine

    ActiveRecord::Base.transaction do
      # I care only about those here, use other rake task to find duplicates
      %w[operator fmu observer observation country].each do |model|
        remove_query = <<~SQL
          delete from #{model}_translations a
            using #{model}_translations b
          where a.updated_at < b.updated_at
            and a.#{model}_id = b.#{model}_id
            and a.locale = b.locale
        SQL

        puts "Removing #{model} translations duplicates: #{ActiveRecord::Base.connection.delete(remove_query)}"
      end

      raise ActiveRecord::Rollback unless for_real
    end
  end

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

      puts "Syncing scores..."
      SyncTasks.new(as_rake_task: false).sync_scores
      puts "Refreshing ranking..."
      RankingOperatorDocument.refresh

      raise ActiveRecord::Rollback unless for_real
    end
  end
end
