namespace :observation_scores do
  desc 'Creates the observations scores for all operators'
  task calculate: :environment do
    puts 'Going to update the observation_scores for all operators'
    operators = Operator.where(obs_per_visit: nil)
    operators.each do |operator|
      operator.calculate_observations_scores
      puts "... #{operator.operator_id}"
    end
    Operator.calculate_scores
  end
end
