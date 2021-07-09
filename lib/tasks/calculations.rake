namespace :documents do
  desc 'Updates the percentage'
  task percentages: :environment do
    Operator.find_each { |o| ScoreOperatorDocument.recalculate!(o) }
  end
end
