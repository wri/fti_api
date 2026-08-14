require "benchmark"
require "csv"

namespace :fix do
  # One time repair of the two operator documents deleted on 2026-08-21 by the forest type
  # string/symbol comparison bug in RequiredOperatorDocumentFmu#applies_to_forest_type?.
  # The documents were restored by hand, this removes everything else the deletion left behind.
  # SKIP_STATISTICS=true leaves the statistics alone, for when a backfill regenerates them anyway.
  task erroneous_document_deletion: :environment do
    for_real = ENV["FOR_REAL"] == "true"
    skip_statistics = ENV["SKIP_STATISTICS"] == "true"
    puts "DRY RUN, pass FOR_REAL=true to apply" unless for_real
    puts "Skipping statistics regeneration" if skip_statistics

    document_ids = [19045, 19349]
    statistic_country_ids = [45, nil]

    ActiveRecord::Base.transaction do
      documents = OperatorDocument.where(id: document_ids)
      raise "expected #{document_ids.size} live documents, found #{documents.count}" unless documents.count == document_ids.size

      operator_ids = documents.distinct.pluck(:operator_id)
      raise "expected a single operator, found #{operator_ids.inspect}" unless operator_ids.size == 1

      operator_id = operator_ids.first

      versions = PaperTrail::Version.where(
        item_type: %w[OperatorDocument OperatorDocumentFmu OperatorDocumentCountry],
        item_id: document_ids, event: "destroy"
      )
      raise "expected #{document_ids.size} destroy versions, found #{versions.count}" unless versions.count == document_ids.size

      deletion_time = versions.minimum(:created_at)
      puts "Deletion at #{deletion_time}, operator #{operator_id}"

      histories = OperatorDocumentHistory.only_deleted.where(operator_document_id: document_ids)
      raise "expected #{document_ids.size} deleted history rows, found #{histories.count}" unless histories.count == document_ids.size

      histories.each do |history|
        raise "history #{history.id} was not born deleted" unless (history.deleted_at - history.created_at).abs < 1
        raise "history #{history.id} has annexes" if history.annex_documents.any?

        puts "Purging history #{history.id} (operator document #{history.operator_document_id})"
        history.really_destroy!
      end

      puts "Deleting #{versions.count} destroy versions: #{versions.pluck(:id).inspect}"
      versions.delete_all

      # the restore moved updated_at forward, put it back on the last real change so it lines up with history
      documents.each do |document|
        last_history = OperatorDocumentHistory.where(operator_document_id: document.id).order(:operator_document_updated_at).last
        raise "no history left for document #{document.id}" if last_history.nil?

        puts "Document #{document.id} updated_at #{document.updated_at} -> #{last_history.operator_document_updated_at}"
        document.update_columns(updated_at: last_history.operator_document_updated_at)
      end

      # the deletion recalculated the score, which added a score for that day and superseded the then
      # current one. Only that score is an artifact, later ones would have been created anyway because
      # their summaries differ from the superseded score.
      superseded_score = ScoreOperatorDocument.where(operator_id: operator_id)
        .where("created_at < ?", deletion_time).order(:created_at, :id).last
      raise "no score from before the deletion for operator #{operator_id}" if superseded_score.nil?

      bug_scores = ScoreOperatorDocument.where(operator_id: operator_id, date: deletion_time.to_date).to_a
      raise "expected one score dated #{deletion_time.to_date}, found #{bug_scores.map(&:id).inspect}" unless bug_scores.size == 1

      bug_score = bug_scores.first
      raise "score #{bug_score.id} is current, refusing to delete it" if bug_score.current?

      expected_total = superseded_score.total - document_ids.size
      raise "score #{bug_score.id} has total #{bug_score.total}, expected #{expected_total}" unless bug_score.total == expected_total

      successor_score = ScoreOperatorDocument.where(operator_id: operator_id)
        .where("created_at > ?", bug_score.created_at).order(:created_at, :id).first
      raise "nothing superseded score #{bug_score.id}" if successor_score.nil?

      puts "Deleting score #{bug_score.id} (date #{bug_score.date}, total #{bug_score.total})"
      ScoreOperatorDocument.where(id: bug_score.id).delete_all

      puts "Score #{superseded_score.id} updated_at #{superseded_score.updated_at} -> #{successor_score.created_at}"
      superseded_score.update_columns(updated_at: successor_score.created_at)

      unless skip_statistics
        # every statistic from the deletion day onwards was generated while the documents were hidden
        statistic_days = OperatorDocumentStatistic
          .where(country_id: statistic_country_ids)
          .where("date >= ?", deletion_time.to_date)
          .distinct.order(:date).pluck(:date)

        statistic_days.each do |day|
          statistic_country_ids.each do |country_id|
            puts "Regenerating document statistics for country #{country_id.inspect} on #{day}"
            OperatorDocumentStatistic.generate_for_country_and_day(country_id, day, true)
          end
        end
      end

      puts
      puts "Verification:"
      [deletion_time.to_date, Date.current].uniq.each do |day|
        visible = OperatorDocumentHistory.at_date(day).where(operator_document_id: document_ids).count
        puts "  #{day}: #{visible} of #{document_ids.size} documents visible in history"
      end
      ScoreOperatorDocument.where(operator_id: operator_id).order(:date, :id).last(3).each do |score|
        puts "  score #{score.id} date=#{score.date} current=#{score.current} all=#{score.all} total=#{score.total}"
      end

      raise ActiveRecord::Rollback unless for_real
    end

    puts for_real ? "Applied." : "Rolled back."
  end

  task annexes: :environment do
    ActiveRecord::Base.transaction do
      for_real = ENV["FOR_REAL"] == "true"

      orphaned_before = OperatorDocumentAnnex.unscoped.orphaned.count
      puts "Orhpaned annexes before: #{orphaned_before}"

      # expect to have 46 less orphaned annexes
      parse_csv = ->(filepath) do
        strip_converter = ->(field) { field&.strip }
        CSV.parse(
          File.read(File.join(Rails.root, "db", "files", "annex_fix", filepath)),
          headers: true,
          converters: [strip_converter],
          header_converters: :symbol
        )
      end
      annexes_connections_before_migration = parse_csv.call("annexes_before_migration.csv")
      annexes_orphaned_after_history_clean = parse_csv.call("annexes_46_before_clean.csv")

      # ods_ids = OperatorDocumentHistory
      #   .where(id: AnnexDocument.where(documentable_type: "OperatorDocumentHistory").pluck(:documentable_id))
      #   .pluck(:operator_document_id)
      #   .uniq

      all_backup = (annexes_connections_before_migration.map(&:to_h) +
                    annexes_orphaned_after_history_clean.map(&:to_h)).uniq

      operator_annexes_backup = all_backup.reject { |x| x[:operator_document_id].blank? }

      doc_ids = operator_annexes_backup.pluck(:operator_document_id).uniq
      all_annexes_ids = operator_annexes_backup.pluck(:operator_document_annex_id).uniq

      puts "Annex history relation before: #{AnnexDocument.where(documentable_type: "OperatorDocumentHistory").count}"

      # code below can remove annexes if csv file with nulls provided
      # to_remove = all_backup.select { |x| x[:operator_document_id].blank? }.map { |x| x[:operator_document_annex_id] }.uniq
      # annexes_to_remove = OperatorDocumentAnnex.where(id: to_remove)
      # versions = PaperTrail::Version.where(item: annexes_to_remove)

      # if for_real
      #   PaperTrail.enabled = false
      #   annexes_to_remove.each(&:really_destroy!)
      #   PaperTrail.enabled = true
      # else
      #   annexes_to_remove.delete_all
      # end

      # versions.delete_all

      OperatorDocument.unscoped.where(id: doc_ids).find_each do |od|
        annexes_ids = operator_annexes_backup
          .select { |x| x[:operator_document_id] == od.id.to_s }
          .pluck(:operator_document_annex_id)
          .uniq
        annexes = OperatorDocumentAnnex.unscoped.where(id: annexes_ids)
        histories = OperatorDocumentHistory.unscoped.where(operator_document_id: od.id).order(:operator_document_updated_at).to_a

        last_not_provided = nil

        histories.each_with_index do |his, index|
          next_version = histories[index + 1]
          last_not_provided = his if his.doc_not_provided?

          # doc_not_provided, no way to have any annex
          # history version will have all previously created annexes for that document
          # and also all annexes created between this version and the next version of document if there is next version
          unless his.doc_not_provided?
            # think about exired
            prev_annexes = annexes.select { |a|
              a.created_at < his.operator_document_updated_at &&
                (last_not_provided.nil? || a.created_at > last_not_provided.operator_document_updated_at)
            }
            next_annexes = annexes.select { |a|
              a.created_at >= his.operator_document_updated_at &&
                (next_version.nil? || a.created_at < next_version.operator_document_updated_at)
            }

            his.operator_document_annexes = prev_annexes + next_annexes
          end

          his.save!(touch: false)
        end
      end

      puts "Annex history relation after: #{AnnexDocument.where(documentable_type: "OperatorDocumentHistory").count}"

      orphaned_after = OperatorDocumentAnnex.unscoped.orphaned.count
      puts "Orhpaned annexes after: #{orphaned_after}"

      still_orphaned = OperatorDocumentAnnex.unscoped.orphaned.where(id: all_annexes_ids)

      puts "still orphaned: #{still_orphaned.count}"

      still_orphaned.each do |annex|
        doc_ids = operator_annexes_backup.select { |x| x[:operator_document_annex_id].to_i == annex.id }.pluck(:operator_document_id).uniq

        puts "BAD DATA for annex #{annex.id}: connected with #{doc_ids.join(",")}" if doc_ids.count != 1
        doc_ids.each do |doc_id|
          doc = OperatorDocument.unscoped.where(id: doc_id).first
          doc_his = OperatorDocumentHistory.unscoped.where(operator_document: doc)

          if doc.nil? && doc_his.empty?
            puts "Orphaned annex: #{annex.id} but document with id: #{doc_id} does not exist in DB"
          else
            puts "Orphaned annex: #{annex.id}, should be connected with doc: #{doc.id}, #{doc.status} (updated_at: #{doc.updated_at}), versions: #{doc.versions.count}, histories: #{doc_his.count}"
          end
        end
      end

      raise ActiveRecord::Rollback unless for_real
    end
  end

  desc "fix doc history"
  task fix_doc_history: :environment do
    date = "2021-04-01"

    # rubocop:disable Lint/ConstantDefinitionInBlock
    OperatorDocumentUploader = Class.new # to fix initialization of old document which used this
    # rubocop:enable Lint/ConstantDefinitionInBlock

    docs_in_history = OperatorDocumentHistory.distinct.pluck(:operator_document_id)

    new_history_list = []

    puts "Docs no history count: #{OperatorDocument.where.not(id: docs_in_history).count}"
    puts "Annex history relation: #{AnnexDocument.where(documentable_type: "OperatorDocumentHistory").count}"

    time = Benchmark.ms do
      ActiveRecord::Base.transaction do
        puts "HistoryCount before: #{OperatorDocumentHistory.count}"

        OperatorDocumentHistory.delete_all
        AnnexDocument.where(documentable_type: "OperatorDocumentHistory").delete_all

        OperatorDocument.unscoped.find_each do |od|
          start_version = od.paper_trail.version_at(date) || od.versions.where(event: "update").where("created_at >= ?", date).where_object(deleted_at: nil).order(:created_at).first&.reify || od

          next if start_version.blank?
          next if start_version.deleted_at.present?

          puts "Recreating history for operator document #{od.id}"

          current_annexes = od.operator_document_annexes

          version = start_version

          loop do
            version.user_id = nil if version.user_id.in? [100001, 100002, 100008, 100010, 100011, 100013]

            new_history = version.build_history
            next_version = version.paper_trail.next_version

            # doc_not_provided, no way to have any annex
            # history version will have all previously created annexes for that document
            # and also all annexes created between this version and the next version of document if there is next version
            unless new_history.doc_not_provided?
              prev_annexes = current_annexes.select { |a| a.created_at < version.updated_at }
              next_annexes = current_annexes.select { |a| a.created_at >= version.updated_at && (next_version.nil? || a.created_at < next_version.updated_at) }

              new_history.operator_document_annexes = prev_annexes + next_annexes
            end

            new_history_list << new_history

            break if next_version.nil?

            version = next_version
          end
        end

        puts "Bulk import history data..."
        OperatorDocumentHistory.import new_history_list, recursive: true

        # TODO: think about more indicators of healthy history
        # TODO: what about document_file and attachments, check if all documents have correct attachments
        docs_in_history = OperatorDocumentHistory.distinct.pluck(:operator_document_id)

        puts "HistoryCount after: #{OperatorDocumentHistory.count}"
        puts "Docs no history count: #{OperatorDocument.where.not(id: docs_in_history).count}"
        puts "Docs no history ids: #{OperatorDocument.where.not(id: docs_in_history).pluck(:id)}"
        puts "Annex history relation after: #{AnnexDocument.where(documentable_type: "OperatorDocumentHistory").count}"

        raise ActiveRecord::Rollback if ENV["FOR_REAL"].blank?
      end
    end

    puts "History recreated in #{time} ms."
  end

  desc "Fixing score operator document history"
  task score_operator_documents: :environment do
    puts "FOR REAL!!!" if ENV["FOR_REAL"].present?

    ActiveRecord::Base.transaction do
      scores_to_remove_ids = []

      Operator.find_each do |operator|
        # How to fix the history?
        # fix current, change current to be the added as  the last one
        # take the latest from the day if there are multiple, recalculate 'all' field based on summary
        # remove the rest from the same day, in that way we will get rid of duplicates from the same day
        # now for each operator get the whole history and starting from the beginning check if
        # next entry have to same value, if yes then remove it
        # THINK ABOUT IT: if on some day, value changes, but then goes back to the previous value, the entry will stay
        # maybe that is ok, and also removing those values is ok too

        current_scores = operator.score_operator_documents.current.order(:created_at)

        # fixing current scores, keep only the last one
        if current_scores.count > 1
          puts "========== FIXING CURRENT SCORES - OPERATOR #{operator.id} =================="

          puts "FOUND #{current_scores.count} current scores for operator #{operator.id}, will keep the last created one"

          kept_score = current_scores.last
          current_scores.where.not(id: kept_score.id).find_each do |s|
            puts "SCORE CHANGE TO CURRENT:FALSE #{print_score(s)}"
          end
          current_scores.where.not(id: kept_score.id).update_all(current: false)

          puts "KEPT CURRENT SCORE #{print_score(kept_score)}"

          operator.reload

          correct_all = calculate_all_score(kept_score)
          if correct_all != kept_score.all
            puts "BUG - all should be #{correct_all} for #{print_score(kept_score)}"
            kept_score.all = correct_all
            kept_score.save!(touch: false) # do not update timestamps
          end

          # sane check
          if operator.score_operator_documents.current.count != 1
            puts "SANE CHECK - STILL SMTH WRONG"
            raise ActiveRecord::Rollback
          end

          puts "========== END OF FIXING CURRENT SCORES - OPERATOR #{operator.id} =================="
        end
        scores = operator.score_operator_documents.order(:date, created_at: :desc).to_a

        # items will be ordered by date asc and created_at desc, meaning the first one from
        # give date is the one we want to keep, the rest we will push to be deleted
        scores.each do |score|
          next if scores_to_remove_ids.include?(score.id) # if pushed to remove move to next item

          # keep the last one from the date and recaluclate all if needed
          # because it should be only one for the date
          scores_with_same_date = scores.select { |s| s.date == score.date && s.id != score.id }
          scores_to_remove_ids.push(*scores_with_same_date.map(&:id))

          if scores_with_same_date.count > 0
            puts "SCORE WILL BE KEPT #{print_score(score)}"
            scores_with_same_date.each do |s|
              puts "SCORE WILL BE DELETED #{print_score(s)}"
            end
          end
        end
      end

      puts "REMOVING #{scores_to_remove_ids.count} scores"
      ScoreOperatorDocument.where(id: scores_to_remove_ids).delete_all

      puts "========== FIXING INCORRECT SCORES =================="
      # now take a look if scores are correct
      ScoreOperatorDocument.find_each do |sod|
        correct_all = calculate_all_score(sod)
        if correct_all != sod.all
          puts "BUG - all should be #{correct_all} for #{print_score(sod)} - FIXING!"
          sod.update_columns(all: correct_all)
        end
      end
      puts "========== END OF FIXING INCORRECT SCORES =================="

      # SANE CHECK
      ScoreOperatorDocument.find_each do |sod|
        correct_all = calculate_all_score(sod)
        if correct_all != sod.all
          puts "SANE CHECK WHEN CHECKING ALL VALUE - STILL SMTH WRONG"
          raise ActiveRecord::Rollback
        end
      end
      puts "ALL GOOD!!"
      # still fmu, and country precalculated values would be wrong :/

      raise ActiveRecord::Rollback if ENV["FOR_REAL"].blank?
    end
  end

  def print_score(sod)
    "id: #{sod.id} date: #{sod.date} all: #{sod.all} summary_public: #{sod.summary_public}"
  end

  def calculate_all_score(sod)
    sod.summary_public["doc_valid"] / (sod.total.to_f - sod.summary_public["doc_not_required"])
  end

  desc "Fixing operator document generated names"
  task operator_documents_names: :environment do
    count_no_relation = 0
    count_no_operator = 0
    count_wrong_name = 0
    count_file_not_exists = 0

    DocumentFile.find_each do |df|
      if df.owner.nil?
        puts "NO relation for document #{df.id}"
        count_no_relation += 1
        next
      end

      operator = df.owner.operator
      if operator.nil?
        puts "NO operator document for #{df.id}"
        count_no_operator += 1
        next
      end

      filename = df.attachment.identifier
      next if /\d{4}-\d{2}-\d{2}/.match?(filename) # have date in filename then I would say it is ok

      start_name = operator.name[0...30]&.parameterize
      next if df.attachment.identifier.start_with?(start_name)

      new_name = [
        operator.name[0...30]&.parameterize,
        df.owner.required_operator_document.name[0...100]&.parameterize,
        df.created_at.strftime("%Y-%m-%d")
      ].compact.join("-") + File.extname(filename)

      file_dirname = File.dirname(df.attachment.file.file)
      new_file_path = File.join(file_dirname, new_name)

      puts "WRONG NAME for #{df.id} #{df.attachment.identifier} will be changed to #{new_name}"
      count_wrong_name += 1

      if df.attachment.blank?
        puts "NO file for #{df.id}"
        count_file_not_exists += 1
        next
      end

      if ENV["FOR_REAL"]
        df.attachment.file.move!(new_file_path)
        df.update_columns(attachment: new_name)
      end
    end

    puts "TOTAL COUNT #{DocumentFile.count}"
    puts "NO OPERATORS #{count_no_operator}"
    puts "NO RELATION #{count_no_relation}"
    puts "WRONG NAME #{count_wrong_name}"
    puts "WRONG FILE DOES NOT EXIST #{count_file_not_exists}"
  end

  desc "Fixing operator document annexes generated names"
  task annexes_names: :environment do
    no_suffix = 0
    no_file = 0
    no_operator_document_record = 0
    non_required_document = 0

    # fixing only those with no_document in the name
    OperatorDocumentAnnex.find_each do |oda|
      next unless oda.attachment.identifier.include?("no_document")

      # first look into the history
      first_history_entry = oda.operator_document_histories.order(operator_document_updated_at: :asc).first
      operator_document_record = first_history_entry || oda.operator_document

      if operator_document_record.blank?
        puts "NO operator document for annex #{oda.id}, skipping"
        no_operator_document_record += 1
        next
      end

      document_file = operator_document_record.document_file

      if document_file.nil? && operator_document_record.reason.present?
        # puts "Looks like annex #{oda.id} is for non required document, document status is: #{operator_document_record.status} skipping"
        non_required_document += 1
        next
      end

      new_suffix = document_file&.attachment&.file&.basename&.parameterize&.first(200)

      if new_suffix.blank?
        puts "NO new suffix for annex #{oda.id}, operator document: #{oda.operator_document&.id}, annex documents history: #{oda.annex_documents_history.count}"
        no_suffix += 1
        next
      end

      unless File.exist?(oda.attachment.file.file)
        puts "File for annex #{oda.id} does not exist, skipping"
        no_file += 1
        next
      end

      new_name = oda.attachment.identifier.gsub("no_document", new_suffix)
      puts "Changing annex #{oda.id} name from #{oda.attachment.identifier} to new name: #{new_name}"
      file_dirname = File.dirname(oda.attachment.file.file)
      new_file_path = File.join(file_dirname, new_name)

      if ENV["FOR_REAL"]
        oda.attachment.file.move!(new_file_path)
        oda.update_columns(attachment: new_name)
      end
    end

    puts "No suffix count: #{no_suffix}"
    puts "No file count: #{no_file}"
    puts "No operator document record count: #{no_operator_document_record}"
    puts "Non required document count: #{non_required_document}"
  end

  desc "One-time fix of annexes left from fixing annexes filenames investigation (Aug 2026)"
  task annexes_names_leftovers: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts for_real ? "RUNNING FOR REAL" : "DRY RUN"

    # annexes 100613, 100912, 100914, 100915 are left as they are, no document file to derive the name from
    # 100155 applies to the current version of its document, the rest only to the version history they were uploaded for
    target_connections = {
      100155 => {"OperatorDocument" => [19354], "OperatorDocumentHistory" => [69865]},
      100207 => {"OperatorDocumentHistory" => [79685, 79697, 79698, 82783]},
      100653 => {"OperatorDocumentHistory" => [85673, 85705, 86909]},
      100703 => {"OperatorDocumentHistory" => [86550, 86561, 86562]}
    }

    ActiveRecord::Base.transaction do
      target_connections.each do |annex_id, documentables|
        documentables.each do |documentable_type, documentable_ids|
          documentable_ids.each do |documentable_id|
            next if AnnexDocument.exists?(operator_document_annex_id: annex_id,
              documentable_type: documentable_type, documentable_id: documentable_id)

            puts "Connecting annex #{annex_id} with #{documentable_type} #{documentable_id}"
            AnnexDocument.create!(operator_document_annex_id: annex_id,
              documentable_type: documentable_type, documentable_id: documentable_id)
          end
        end

        AnnexDocument.where(operator_document_annex_id: annex_id).find_each do |link|
          next if documentables[link.documentable_type]&.include?(link.documentable_id)

          puts "Removing connection of annex #{annex_id} with #{link.documentable_type} #{link.documentable_id}"
          link.destroy!
        end
      end

      target_connections.each_key do |annex_id|
        annex = OperatorDocumentAnnex.find(annex_id)

        unless annex.attachment.identifier.to_s.include?("no_document")
          puts "Annex #{annex.id} name already fixed, skipping"
          next
        end

        operator_document_record = annex.operator_document_histories.order(operator_document_updated_at: :asc).first ||
          annex.operator_document
        document_file = operator_document_record&.document_file

        if document_file&.attachment&.file.blank?
          puts "NO document file to derive the name from for annex #{annex.id}, skipping"
          next
        end

        unless File.exist?(annex.attachment.file.file)
          puts "File for annex #{annex.id} does not exist, skipping"
          next
        end

        old_name = annex.attachment.identifier
        new_suffix = document_file.attachment.file.basename.parameterize.first(200)
        new_name = old_name.gsub("no_document", new_suffix)
        puts "Changing annex #{annex.id} name from #{old_name} to new name: #{new_name}"
        new_file_path = File.join(File.dirname(annex.attachment.file.file), new_name)

        annex.attachment.file.move!(new_file_path) if for_real
        annex.update_columns(attachment: new_name)

        # also take a peek into paper trail history and update the filenames there
        # object and object_changes are jsonb, filename sits nested in the serialized uploader
        annex.versions.each do |version|
          new_object = version.object && JSON.parse(version.object.to_json.gsub(old_name, new_name))
          new_object_changes = version.object_changes && JSON.parse(version.object_changes.to_json.gsub(old_name, new_name))

          next if new_object == version.object && new_object_changes == version.object_changes

          version.update_columns(object: new_object, object_changes: new_object_changes)
          puts "Updated paper trail version #{version.id}"
        end
      end

      Rails.cache.delete_matched(/operator_document_annexes/) if for_real

      raise ActiveRecord::Rollback unless for_real
    end
  end

  desc "Fix filenames saved in db for annexes with timestamp mismatch"
  task annexes_timestamps: :environment do
    for_real = ENV["FOR_REAL"] == "true"

    puts "RUNNING FOR REAL" if for_real
    puts "DRY RUN" unless for_real

    ActiveRecord::Base.transaction do
      OperatorDocumentAnnex.find_each do |annex|
        next if annex.attachment.present?

        File.dirname(annex.attachment.file.file).tap do |dir|
          files = Dir.glob("#{dir}/*").select { |f| File.file?(f) }
          if files.empty?
            puts "!!! No files found in directory: #{dir}"
            next
          end
          if files.count > 1
            puts "!!! Multiple files found in directory: #{dir}, cannot fix attachment filename for annex #{annex.id}"
            next
          end
          file = files.first
          # get the number from the filename (filename starts with Annex_{number}) and compare to the number from saved filename in db
          if file =~ /Annex_(\d+)_/
            file_number = $1.to_i
            db_number = annex.attachment.file.file.match(/Annex_(\d+)_/)[1].to_i
            # if number is different by max value of 2
            if (file_number - db_number).abs <= 2
              puts "Fixing annex #{annex.id} attachment filename from #{File.basename(annex.attachment.file.file)} to #{File.basename(file)}"
              annex.update_columns(attachment: File.basename(file))
              # also take a peek into paper trail history and update the filenames there
              annex.versions.each do |version|
                new_object = version.object&.gsub("Annex_#{db_number}_", "Annex_#{file_number}_")
                new_object_changes = version.object_changes.gsub("Annex_#{db_number}_", "Annex_#{file_number}_")

                next if new_object == version.object && new_object_changes == version.object_changes

                version.update_columns(object: new_object, object_changes: new_object_changes)
                puts "Updated paper trail version #{version.id}"
              end
            else
              puts "!!! Cannot fix annex #{annex.id} attachment filename, number mismatch: file number #{file_number}, db number #{db_number}"
            end
          else
            puts "!!! No valid filename found in directory: #{dir} for annex #{annex.id}"
          end
        end
      end

      Rails.cache.delete_matched(/operator_document_annexes/) if for_real

      raise ActiveRecord::Rollback unless for_real
    end
  end
end
