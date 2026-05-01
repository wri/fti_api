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

  desc "Warn and deactivate inactive users"
  task deactivate_inactive_users: :environment do
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    Rails.logger.info "Going to process inactive users at: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}"

    warning_threshold = 18.months.ago.end_of_day
    warning_cooldown = 1.month.ago.end_of_day
    deactivation_threshold = 2.years.ago.end_of_day

    warned_users = 0
    deactivated_users = 0

    time = Benchmark.ms do
      warning_users = User.where(is_active: true)
        .where("COALESCE(last_sign_in_at, created_at) <= ?", warning_threshold)
        .where("COALESCE(last_sign_in_at, created_at) > ?", deactivation_threshold)
        .where("last_inactivity_warning_sent_at IS NULL OR last_inactivity_warning_sent_at <= ?", warning_cooldown)

      warning_users.find_each do |user|
        disable_date = (user.last_sign_in_at || user.created_at).to_date + 2.years
        I18n.with_locale(user.locale.presence || I18n.default_locale) do
          UserMailer.inactive_account_warning(user, disable_date).deliver_now
        end
        user.update!(last_inactivity_warning_sent_at: Time.zone.now)
        warned_users += 1
      end

      users_to_deactivate = User.where(is_active: true)
        .where("COALESCE(last_sign_in_at, created_at) <= ?", deactivation_threshold)

      users_to_deactivate.find_each do |user|
        user.update!(is_active: false, deactivated_at: Time.zone.now)
        I18n.with_locale(user.locale.presence || I18n.default_locale) do
          UserMailer.account_deactivated_for_inactivity(user).deliver_now
        end
        deactivated_users += 1
      end
    end

    Rails.logger.info "Processed inactive users. Warned=#{warned_users}, Deactivated=#{deactivated_users}. It took #{time} ms."
    Rails.logger.info "::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
  end
end
