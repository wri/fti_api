namespace :observations do
  desc 'Hide observations older than 5 year'
  task hide: :environment do
    Observation.where("publication_date < ?", Date.today - 5.years).update_all(hidden: true)
  end

  desc 'Recalculate observation scores for operators'
  task recalculate_scores: :environment do
    operators = Operator.where(id: ScoreOperatorObservation.pluck(:operator_id).uniq)
    operators.each do |op|
      ScoreOperatorObservation.recalculate!(op)
    end
  end

  task recreate_history: :environment do
    ActiveRecord::Base.transaction do
      ObservationHistory.delete_all

      total_obs = Observation.count
      index = 1
      puts "Total observations: #{total_obs}"
      Observation.unscoped.find_each do |observation|
        puts "Recreating history for observation #{index} with id: #{observation.id}"
        observation.versions.each do |version|
          o = version.reify
          next if o.nil?

          if o.operator_id.present? && Operator.unscoped.where(id: o.operator_id).count.zero?
            puts "operator #{o.operator_id} does not exist, skipping"
            next
          end

          o.create_history
        end
        observation.create_history
        index = index + 1
      end
    end
  end

  desc 'Task that will rename existing evidence document files'
  task rename_evidence_files: :environment do
    ObservationDocument.find_each do |od|
      next unless od.attachment?

      od.attachment.recreate_versions!
      od.save!
      puts "Evidence document #{od.id} new filename #{od.attachment.filename}"
    end
  end

  desc 'Set resposible admin by default'
  task set_responsible_admin: :environment do
    Observer.unscoped.find_each do |observer|
      puts "Setting responsible admin by default for observer with id: #{observer.id}"
      observer.set_responsible_admin
      observer.save!
    end

    Observation.unscoped.find_each do |observation|
      puts "Setting responsible admin by default for observation with id: #{observation.id}"
      observation.set_default_responsible_admin
      puts observation.responsible_admin_id
      observation.save!
    end
  end
end
