class SyncTasks
  include Rake::DSL

  def initialize
    namespace :sync do
      desc 'Sync scores saved in score operator document'
      task scores: :environment do
        different_scores = 0

        # This helps to recalculate scores taking document history how it was a the date of the score to be saved
        ScoreOperatorDocument.find_each do |score|
          docs = OperatorDocumentHistory.from_operator_at_date(score.operator_id, score.date)

          sod = ScoreOperatorDocument.new date: Date.today, operator: score.operator, current: true
          calculator = ScoreOperatorCalculator.new(docs)
          sod.all = calculator.all
          sod.fmu = calculator.fmu
          sod.country = calculator.country
          sod.total = calculator.total
          sod.summary_private = calculator.summary_private
          sod.summary_public = calculator.summary_public

          if sod != score
            puts "SOD DIFFERENT: id: #{score.id}"
            score_json = score.as_json(only: [:all, :fmu, :country, :total, :summary_public, :summary_private])
            sod_json = sod.as_json(only: [:all, :fmu, :country, :total, :summary_public, :summary_private])

            compare(score_json, sod_json)
            different_scores += 1

            if ENV["FOR_REAL"].present?
              score.all = sod.all
              score.fmu = sod.fmu
              score.country = sod.country
              score.total = sod.total
              score.summary_private = sod.summary_private
              score.summary_public = sod.summary_public
              score.save!
            end
          end
        end

        puts "TOTAL: #{ScoreOperatorDocument.count}"
        puts "DIFFERENT: #{different_scores}"
      end
    end
  end

  def compare(actual_json, expected_json)
    actual_json.each do |key, value|
      if value.is_a? Hash
        compare(value, expected_json[key])
      else
        puts "#{key}: + #{value}, - #{expected_json[key]} " if value != expected_json[key]
      end
    end
  end
end

SyncTasks.new
