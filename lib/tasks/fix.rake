require 'csv'

namespace :fix do
  desc 'Fixing score operator document history'
  task score_operator_documents: :environment do
    ActiveRecord::Base.transaction do
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
          puts "FOUND #{current_scores.count} current scores for operator #{operator.id}, will keep the last created one"

          kept_score = current_scores.last
          current_scores.where.not(id: kept_score.id).delete_all

          operator.reload

          correct_all = calculate_all_score(kept_score)
          if correct_all != kept_score.all
            puts "BUG #{kept_score.id} - is #{kept_score.all} and should be #{correct_all}"
            kept_score.all = correct_all
            kept_score.save!(touch: false) # do not update timestamps
          end

          # sane check
          if operator.score_operator_documents.current.count != 1
            puts "SANE CHECK - STILL SMTH WRONG"
            raise ActiveRecord::Rollback
          end
        end

        scores = operator.score_operator_documents.order(:date)
      end

      raise ActiveRecord::Rollback unless ENV['FOR_REAL'].present?
    end
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
