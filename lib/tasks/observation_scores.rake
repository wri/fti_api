namespace :observation_scores do
  desc 'Created all the operation scores starting on the first observation until today'
  task generate: :environment do
    date = Observation.order(created_at: :asc).first.created_at.to_date
    while date <= Date.today
      GlobalObservationScoreService.new(date).call
      puts date
      date += 1.day
    end
  end
end
