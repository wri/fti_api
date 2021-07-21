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
end
