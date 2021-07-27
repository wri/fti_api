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
        # sync_global_scores(Date.new(2021,4,1))
        sync_global_scores(Date.new(2021,4,1))
      end
    end
  end

  def sync_global_scores(from_date)
    (from_date..Date.new(2021,7,1)).each do |day|
      countries = Country.active.pluck(:id).uniq + [nil]
      countries.each do |country_id|
        puts "Checking score for country: #{country_id} and #{day}"
        GlobalScore.transaction do
          gs = GlobalScore.find_or_initialize_by(country_id: country_id, date: day)
          docs = OperatorDocumentHistory.at_date(day)
            .non_signature
            .left_joins(:fmu)
            .select(:status, 'operator_document_histories.type', 'fmus.forest_type', 'required_operator_documents.required_operator_document_group_id')
          docs = docs.where(required_operator_documents: { country_id: country_id }) if country_id.present?

          gs.general_status = docs.group_by(&:status).map do |status, docs|
            {
              status => docs.map do |d|
                {
                  t: d.type === 'OperatorDocumentCountryHistory' ? 'country' : 'fmu',
                  g: d.required_operator_document_group_id,
                  f: d.forest_type
                }
              end
            }
          end.reduce(&:merge)

          prev_score = gs.previous_score
          next if prev_score.present? && prev_score == gs

          puts "Adding score for country: #{country_id} and #{day}"
          gs.save!
        end
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
