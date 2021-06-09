require 'benchmark'
namespace :scheduler do

  desc 'Expires documents'
  task expire: :environment do
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to expire documents at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms { OperatorDocument.expire_documents }
    Rails.logger.info "Documents expired. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end

  desc 'Calculate scores'
  task calculate_scores: :environment do
    # TODO: REMOVE THIS job after deploy
  end

  desc 'Change current active FMU Operators'
  task set_active_fmu_operator: :environment do
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to set the active FMU Operator at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms { FmuOperator.calculate_current }
    Rails.logger.info "Active FMU Operators set calculated. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end

  desc 'Calculate the Global Scores'
  task global_scores: :environment do
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to update the global scores. at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms { GlobalScoreService.new.call }
    Rails.logger.info "Finished updating the global scores. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end
end
