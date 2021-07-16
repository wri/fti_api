require 'benchmark'
require 'csv'

namespace :fix do
  task annexes: :environment do
    ActiveRecord::Base.transaction do
      for_real = ENV['FOR_REAL'] == 'true'

      orphaned_before = OperatorDocumentAnnex.unscoped.orphaned.count
      puts "Orhpaned annexes before: #{orphaned_before}"

      # expect to have 46 less orphaned annexes
      parse_csv = ->(filepath) do
        strip_converter = ->(field) { field&.strip }
        CSV.parse(
          File.read(File.join(Rails.root, 'tmp', filepath)),
          headers: true,
          converters: [strip_converter],
          header_converters: :symbol
        )
      end
      annexes_connections_before_migration = parse_csv.call('annexes_before_migration.csv')
      annexes_orphaned_after_history_clean = parse_csv.call('annexes_46_before_clean.csv')

      ods_ids = OperatorDocumentHistory.
        where(id: AnnexDocument.where(documentable_type: 'OperatorDocumentHistory').pluck(:documentable_id)).
        pluck(:operator_document_id).
        uniq

      all_backup = (annexes_connections_before_migration.map(&:to_h) +
                    annexes_orphaned_after_history_clean.map(&:to_h)).uniq

      operator_annexes_backup = all_backup.reject { |x| x[:operator_document_id].blank? }

      doc_ids = operator_annexes_backup.map { |x| x[:operator_document_id] }.uniq
      all_annexes_ids = operator_annexes_backup.map { |x| x[:operator_document_annex_id] }.uniq

      puts "Annex history relation before: #{AnnexDocument.where(documentable_type: 'OperatorDocumentHistory').count}"

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
          .map { |x| x[:operator_document_annex_id] }
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

      puts "Annex history relation after: #{AnnexDocument.where(documentable_type: 'OperatorDocumentHistory').count}"

      orphaned_after = OperatorDocumentAnnex.unscoped.orphaned.count
      puts "Orhpaned annexes after: #{orphaned_after}"

      still_orphaned = OperatorDocumentAnnex.unscoped.orphaned.where(id: all_annexes_ids)

      puts "still orphaned: #{still_orphaned.count}"

      still_orphaned.each do |annex|
        doc_ids = operator_annexes_backup.select { |x| x[:operator_document_annex_id].to_i == annex.id }.map { |x| x[:operator_document_id] }.uniq

        puts "BAD DATA for annex #{annex.id}: connected with #{doc_ids.join(',')}" if doc_ids.count != 1
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

  desc 'fix doc history'
  task fix_doc_history: :environment do
    date = '2021-04-01'

    OperatorDocumentUploader = Class.new # to fix initialization of old document which used this

    docs_in_history = OperatorDocumentHistory.pluck(:operator_document_id).uniq

    new_history_list = []

    puts "Docs no history count: #{OperatorDocument.where.not(id: docs_in_history).count}"
    puts "Annex history relation: #{AnnexDocument.where(documentable_type: 'OperatorDocumentHistory').count}"

    time = Benchmark.ms do
      ActiveRecord::Base.transaction do
        puts "HistoryCount before: #{OperatorDocumentHistory.count}"

        OperatorDocumentHistory.delete_all
        AnnexDocument.where(documentable_type: 'OperatorDocumentHistory').delete_all

        OperatorDocument.unscoped.find_each do |od|
          start_version = od.paper_trail.version_at(date) || od.versions.where(event: 'update').where('created_at >= ?', date).where_object(deleted_at: nil).order(:created_at).first&.reify || od

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
        docs_in_history = OperatorDocumentHistory.pluck(:operator_document_id).uniq

        puts "HistoryCount after: #{OperatorDocumentHistory.count}"
        puts "Docs no history count: #{OperatorDocument.where.not(id: docs_in_history).count}"
        puts "Docs no history ids: #{OperatorDocument.where.not(id: docs_in_history).pluck(:id)}"
        puts "Annex history relation after: #{AnnexDocument.where(documentable_type: 'OperatorDocumentHistory').count}"

        raise ActiveRecord::Rollback unless ENV['FOR_REAL'].present?
      end
    end

    puts "History recreated in #{time} ms."
  end

  desc 'Fixing score operator document history'
  task score_operator_documents: :environment do
    puts "FOR REAL!!!" if ENV['FOR_REAL'].present?

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

      raise ActiveRecord::Rollback unless ENV['FOR_REAL'].present?
    end
  end

  def print_score(sod)
    "id: #{sod.id} date: #{sod.date} all: #{sod.all} summary_public: #{sod.summary_public}"
  end

  def calculate_all_score(sod)
    sod.summary_public['doc_valid'] / (sod.total.to_f - sod.summary_public['doc_not_required'])
  end

  desc 'Fixing operator document generated names'
  task operator_documents_names: :environment do
    count_no_relation = 0
    count_no_operator = 0
    count_wrong_name = 0
    count_file_not_exists = 0

    DocumentFile.find_each do |df|
      if df.owner.nil?
        puts "NO relation for document #{df.id}"
        count_no_relation +=1
        next
      end

      operator = df.owner.operator
      if operator.nil?
        puts "NO operator document for #{df.id}"
        count_no_operator += 1
        next
      end

      filename = df.attachment.identifier
      next if filename.match(/\d{4}-\d{2}-\d{2}/) # have date in filename then I would say it is ok

      start_name = operator.name[0...30]&.parameterize
      next if df.attachment.identifier.start_with?(start_name)

      new_name = [
        operator.name[0...30]&.parameterize,
        df.owner.required_operator_document.name[0...100]&.parameterize,
        df.created_at.strftime('%Y-%m-%d')
      ].compact.join('-') + File.extname(filename)

      file_dirname = File.dirname(df.attachment.file.file)
      new_file_path = File.join(file_dirname, new_name)

      puts "WRONG NAME for #{df.id} #{df.attachment.identifier} will be changed to #{new_name}"
      count_wrong_name += 1

      unless df.attachment.present?
        puts "NO file for #{df.id}"
        count_file_not_exists += 1
        next
      end

      if ENV["FOR_REAL"]
        df.attachment.file.move!(new_file_path)
        df.update_columns(attachment: new_name)
      end
    end

    puts "TOTAL COUNT #{DocumentFile.all.count}"
    puts "NO OPERATORS #{count_no_operator}"
    puts "NO RELATION #{count_no_relation}"
    puts "WRONG NAME #{count_wrong_name}"
    puts "WRONG FILE DOES NOT EXIST #{count_file_not_exists}"
  end
end
