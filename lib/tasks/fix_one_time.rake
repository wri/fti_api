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

  desc 'Removing documents completely'
  task remove_docs: :environment do
    for_real = ENV['FOR_REAL'] == 'true'
    docs_to_remove = (ENV['DOCS'] || '').split(',')

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    puts "This script will remove #{docs_to_remove.count} documents"

    ActiveRecord::Base.transaction do
      docs = OperatorDocument.unscoped.where(id: docs_to_remove)
      operator_ids = docs.pluck(:operator_id).uniq
      histories = OperatorDocumentHistory.unscoped.where(operator_document_id: docs_to_remove)
      versions = PaperTrail::Version.where(item: docs)

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
      puts "Only for operators: #{operator_ids.join(', ')}"
      SyncTasks.new(as_rake_task: false).sync_scores(operator_id: operator_ids)
      puts "Refreshing ranking..."
      RankingOperatorDocument.refresh

      raise ActiveRecord::Rollback unless for_real
    end
  end

  desc 'Re-assign uploaded attachment to observation reports'
  task observation_report_attachments: :environment do
    # context
    # some reports were renamed couple months ago, files were moved, but after that DB was recreated from backup
    # files now have different name then what is in attachment column
    # I'm going to just check what are the files in uploads directory
    # and update attachment column in DB with the real filename
    for_real = ENV['FOR_REAL'] == 'true'

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    path = Rails.root.join('public', 'uploads', 'observation_report', 'attachment')
    report_filename_hash = Dir.glob("#{path}/**/*")
      .reject {|fn| File.directory?(fn) }
      .map { |file| file.gsub(path.to_s + '/', '') }
      .map { |file| file.split('/') }
      .sort_by { |report_id, filename| report_id.to_i }
      .to_h

    report_filename_hash.transform_keys!(&:to_i)

    puts "COUNT with not existing attachments: #{ObservationReport.all.select { |r| r.read_attribute(:attachment).present? && !r.attachment.exists? }.count}"

    ActiveRecord::Base.transaction do
      ObservationReport.find_each do |report|
        next if report.attachment.nil?

        filename_in_storage = report_filename_hash[report.id]
        next if filename_in_storage.nil?
        next if filename_in_storage == report.read_attribute(:attachment)

        puts "WRONG attachment name for report #{report.id}: is: #{report.read_attribute(:attachment)}, should be: #{filename_in_storage}"

        report.update_columns(attachment: filename_in_storage)
      end

      still_without = ObservationReport.all.select { |r| r.read_attribute(:attachment).present? && !r.attachment.exists? }
      puts "COUNT with not existing attachments: #{still_without.count}"

      still_without.each do |report|
        puts "REPORT #{report.id} still without attachment: #{report.attachment.to_s}"
      end

      raise ActiveRecord::Rollback unless for_real
    end
  end

  desc 'Fixes the bug with wrong observation lnglat'
  task observation_lnglat: :environment do
    for_real = ENV['FOR_REAL'] == 'true'

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    observations = Observation.where.not(fmu: nil)
    observations.find_each do |observation|
      fmu_lng = observation.fmu.geojson.dig('properties', 'centroid', 'coordinates')&.first
      fmu_lat = observation.fmu.geojson.dig('properties', 'centroid', 'coordinates')&.second

      next if fmu_lng.nil? || fmu_lat.nil?

      if observation.lng.nil? || observation.lat.nil?
        puts "NO lng lat for #{observation.id}, fixing"

        observation.lng = fmu_lng
        observation.lat = fmu_lat
        observation.save! if for_real
      elsif observation.lng.round(3) == fmu_lat.round(3) && observation.lat.round(3) == fmu_lng.round(3)
        puts "FOUND wrong lng lat for #{observation.id}, fixing"

        observation.lng = fmu_lng
        observation.lat = fmu_lat
        observation.save! if for_real
      end
    end
  end

  desc 'Tasks to move already deleted reports attachments and evidences to private directory'
  task make_deleted_evidences_private: :environment do
    for_real = ENV['FOR_REAL'] == 'true'

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    puts "Deleted Observation documents/evidence: #{ObservationDocument.deleted.count}"
    puts "With attachment: #{ObservationDocument.deleted.where.not(attachment: ['', nil]).count}"

    missing = 0
    moved = 0

    ObservationDocument.deleted.where.not(attachment: ['', nil]).find_each do |doc|
      next if doc.attachment.exists?

      public_filepath = File.dirname(doc.attachment.file.file.gsub('/private/', '/public/'))
      unless File.exists?(public_filepath)
        puts "missing file: #{public_filepath}"
        missing += 1
        next
      end

      puts "moving file: #{public_filepath}"

      doc.send(:move_attachment_to_private_directory) if for_real
      moved += 1
    end

    puts "Missing files: #{missing}"
    puts "Moved files: #{moved}"
  end

  desc 'Mark expired documents there were expired from not required state as not provided'
  task not_required_expired_move_to_not_provided: :environment do
    for_real = ENV['FOR_REAL'] == 'true'

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    ActiveRecord::Base.transaction do
      docs = OperatorDocument
        .where(status: 'doc_expired', updated_at: 1.month.ago..Date.today)
        .select do |o|
          prev_version_not_required = false
          o.versions.reverse.each do |version|
            next if version.reify.status == 'doc_expired'

            prev_version_not_required = version.reify.status == 'doc_not_required'
            break
          end
          prev_version_not_required
        end

      docs_count = docs.count
      puts "FOUND #{docs.count} docs expired that were not required before"
      puts "DOC_IDS: #{docs.map(&:id).join(',')}"

      # that will regenerate documents to not provided state
      puts "REGENERATING DOCS..."
      docs.each do |doc|
        doc.skip_score_recalculation = true # just do it once for each operator at the end
        doc.destroy!
      end
      docs.map(&:operator).uniq.each { |operator| ScoreOperatorDocument.recalculate!(operator) }

      if docs.each(&:reload).select { |d| d.status == 'doc_not_provided' }.count == docs_count
        puts "ALL GOOD :)"
      else
        puts "ERROR: doc count after docs regenerate does not match"
      end

      raise ActiveRecord::Rollback unless for_real
    end
  end
end
