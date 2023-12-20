require "benchmark"
namespace :scheduler do
  desc "Expires documents"
  task expire: :environment do
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Rails.logger.info "Going to expire operator documents at: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}"
    time = Benchmark.ms { OperatorDocument.expire_documents }
    Rails.logger.info "Operator documents expired. It took #{time} ms."
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"

    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Rails.logger.info "Going to expire government documents at: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}"
    time = Benchmark.ms { GovDocument.expire_documents }
    Rails.logger.info "Government documents expired. It took #{time} ms."
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  end

  desc "Refresh ranking"
  task calculate_scores: :environment do
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Rails.logger.info "Going to recalculate ranking for the whole database: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}"
    time = Benchmark.ms { RankingOperatorDocument.refresh }
    Rails.logger.info "Ranking refreshed. It took #{time} ms."
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  end

  desc "Change current active FMU Operators"
  task set_active_fmu_operator: :environment do
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Rails.logger.info "Going to set the active FMU Operator at: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}"
    time = Benchmark.ms { FmuOperator.calculate_current }
    Rails.logger.info "Active FMU Operators set calculated. It took #{time} ms."
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  end

  desc "Generate Documents Statistics"
  task generate_documents_stats: :environment do
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Rails.logger.info "Going to generate document statistics at: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}"
    time = Benchmark.ms {
      countries = Country.active.pluck(:id).uniq + [nil]
      day = Date.yesterday.to_date
      countries.each do |country_id|
        OperatorDocumentStatistic.generate_for_country_and_day(country_id, day, true)
      end
    }
    Rails.logger.info "Document statistics generated. It took #{time} ms."
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  end

  desc "Generate Observation Reports Statistics"
  task generate_observation_reports_stats: :environment do
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Rails.logger.info "Going to generate observation reports statistics at: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}"
    time = Benchmark.ms {
      countries = Country.with_at_least_one_report.pluck(:id).uniq + [nil]
      day = Date.yesterday.to_date
      countries.each do |country_id|
        ObservationReportStatistic.generate_for_country_and_day(country_id, day, true)
      end
    }
    Rails.logger.info "Observation reports statistics generated. It took #{time} ms."
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  end

  desc "Send quarterly newsletters to operators"
  task send_quarterly_newsletters: :environment do
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Rails.logger.info "Going to send quarterly newsletters: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}"
    failed = false
    time = Benchmark.ms do
      operators = Operator.newsletter_eligible
      operators = operators.where(id: ENV["OPERATOR_IDS"].split(",")) if ENV["OPERATOR_IDS"].present?

      operators.find_each do |operator|
        users = operator.all_users.filter_actives
        users = users.where(id: ENV["USER_IDS"].split(",")) if ENV["USER_IDS"].present?

        users.each do |user|
          I18n.with_locale(user.locale.presence || I18n.default_locale) do
            OperatorMailer.quarterly_newsletter(operator, user).deliver_now
          end
        end
      rescue => e
        failed = true
        Sentry.capture_exception(e, extra: {"operator_id" => operator.id})
      end
    end
    raise "Error while sending quarterly newsletter" if failed
    Rails.logger.info "Sent quarterly newsletters to operators. It took #{time} ms."
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  end
end
