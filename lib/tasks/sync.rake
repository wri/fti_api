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

      task global_scores: :environment do
        sync_global_scores(Date.new(2021,4,1))
      end
    end
  end

  def sync_global_scores(from_date)
    GlobalScore.delete_all

    (from_date..Date.today.to_date).each do |day|
      countries = Country.active.pluck(:id).uniq + [nil]
      countries.each do |country_id|
        GlobalScore.calculate(country_id, day)
      end
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
