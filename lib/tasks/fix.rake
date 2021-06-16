require 'csv'

namespace :fix do
  desc 'fix doc history'
  task fix_doc_history: :environment do
    OperatorDocument.unscoped.find_each do |odh|
      date = '2021-04-27 20:13:11.166133'
      od = odh.paper_trail.version_at(date)

      next if od.blank?
      next if od.deleted_at

      history = OperatorDocumentHistory.where(operator_document_id: od.id).where('updated_at < ?', date)

      unless history.any?
        puts "HISTORY DOES NOT EXISTS #{od.id}"
      end
    end
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
