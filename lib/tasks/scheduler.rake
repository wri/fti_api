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

  desc 'Refresh ranking'
  task calculate_scores: :environment do
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to recalculate ranking for the whole database: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms { RankingOperatorDocument.refresh }
    Rails.logger.info "Ranking refreshed. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end

  desc 'Change current active FMU Operators'
  task set_active_fmu_operator: :environment do
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to set the active FMU Operator at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms { FmuOperator.calculate_current }
    Rails.logger.info "Active FMU Operators set calculated. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end

  desc 'Change current active FMU Operators'
  task set_active_fmu_operator: :environment do
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to set the active FMU Operator at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms { FmuOperator.calculate_current }
    Rails.logger.info "Active FMU Operators set calculated. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end
end
