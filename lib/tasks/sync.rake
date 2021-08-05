class SyncTasks
  include Rake::DSL

  def initialize(as_rake_task: true)
    return unless as_rake_task

    namespace :sync do
      desc 'Sync scores saved in score operator document'
      task scores_all: :environment do
        sync_scores
      end

      desc 'Sync scores saved in score operator document only within last week'
      task scores_last_week: :environment do
        sync_scores(1.week.ago)
      end

      desc 'Refresh ranking'
      task ranking: :environment do
        RankingOperatorDocument.refresh
      end

      task operator_documents_stats: :environment do
        sync_operator_documents_stats(Date.new(2021,5,1))
      end

      task observation_reports_stats: :environment do
        date = ObservationReport.order(created_at: :asc).first.created_at.to_date
        sync_observation_reports_stats(date)
      end
    end
  end

  def sync_operator_documents_stats(from_date)
    OperatorDocumentStatistic.delete_all

    first_day = from_date.to_date
    countries = Country.active.pluck(:id).uniq + [nil]

    (from_date.to_date..Date.today.to_date).each do |day|
      countries.each do |country_id|
        puts "Checking score for country: #{country_id} and #{day}"
        OperatorDocumentStatistic.generate_for_country_and_day(country_id, day, false)
      end
    end
    # after generating all we need to ensure we have stats for first point in time, regenerate for first day only
    countries.each do |country_id|
      puts "FIRST POINT: Checking score for country: #{country_id} and #{first_day}"
      OperatorDocumentStatistic.generate_for_country_and_day(country_id, first_day, true)
    end
  end

  def sync_observation_reports_stats(from_date)
    ObservationReportStatistic.delete_all

    first_day = from_date.to_date
    countries = Country.with_at_least_one_report.pluck(:id).uniq + [nil]

    (from_date..Date.today.to_date).each do |day|
      countries.each do |country_id|
        puts "Checking observation reports for country: #{country_id || 'all'} and #{day}"
        ObservationReportStatistic.generate_for_country_and_day(country_id, day, false)
      end
    end
    # after generating all we need to ensure we have stats for first point in time, regenerate for first day only
    countries.each do |country_id|
      puts "FIRST POINT: Checking observation reports for country: #{country_id || 'all'} and #{first_day}"
      ObservationReportStatistic.generate_for_country_and_day(country_id, first_day, true)
    end
  end

  def sync_scores(date = nil)
    scores = ScoreOperatorDocument.all
    scores = scores.where('date > ?', date) if date.present?
    scores = scores.where(operator_id: ENV['OPERATOR_ID']) if ENV['OPERATOR_ID'].present?

    different_scores = 0
    scores.find_each do |score|
      docs = OperatorDocumentHistory.from_operator_at_date(score.operator_id, score.date)
      expected = ScoreOperatorDocument.build(score.operator, docs)

      if expected != score
        puts "SOD DIFFERENT: id: #{score.id} - #{score.date}, OPERATOR: #{score.operator.name} (#{score.operator_id})"
        score_json = score.as_json(only: [:all, :fmu, :country, :total, :summary_public, :summary_private])
        expected_json = expected.as_json(only: [:all, :fmu, :country, :total, :summary_public, :summary_private])

        compare(score_json, expected_json)
        different_scores += 1

        score.resync! if ENV["FOR_REAL"] == 'true'
      end
    end

    puts "TOTAL: #{scores.count}"
    puts "DIFFERENT: #{different_scores}"
  end

  def compare(actual_json, expected_json)
    actual_json.each do |key, value|
      if value.is_a? Hash
        compare(value, expected_json[key])
      else
        if value != expected_json[key]
          puts "#{key}: actual: #{value}, expected: #{expected_json[key]}"
        else
          puts "#{key}: #{value}"
        end
      end
    end
  end
end

SyncTasks.new
