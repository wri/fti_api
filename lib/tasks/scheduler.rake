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

  desc 'Generate Documents Statistics'
  task generate_documents_stats: :environment do
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to generate document statistics at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms {
      countries = Country.active.pluck(:id).uniq + [nil]
      day = Date.yesterday.to_date
      countries.each do |country_id|
        OperatorDocumentStatistic.generate_for_country_and_day(country_id, day, true)
      end
    }
    Rails.logger.info "Document statistics generated. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end

  desc 'Generate Observation Reports Statistics'
  task generate_observation_reports_stats: :environment do
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
    Rails.logger.info "Going to generate observation reports statistics at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    time = Benchmark.ms {
      countries = Country.with_at_least_one_report.pluck(:id).uniq + [nil]
      day = Date.yesterday.to_date
      countries.each do |country_id|
        ObservationReportStatistic.generate_for_country_and_day(country_id, day, true)
      end
    }
    Rails.logger.info "Observation resports statistics generated. It took #{time} ms."
    Rails.logger.info '::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::'
  end
end
