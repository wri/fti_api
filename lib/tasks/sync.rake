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
        sync_global_scores(Date.new(2021,5,1))
      end

      task global_scores_alt: :environment do
        sync_global_scores_alt(Date.new(2021,5,1))
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

  def sync_global_scores_alt(from_date)
    OperatorDocumentStatistic.delete_all

    (from_date..Date.today.to_date).each do |day|
      countries = Country.active.pluck(:id).uniq + [nil]
      countries.each do |country_id|
        puts "Checking score for country: #{country_id} and #{day}"
        OperatorDocumentStatistic.transaction do
          docs = OperatorDocumentHistory.at_date(day)
            .non_signature
            .left_joins(:fmu)
            .select(:status, 'operator_document_histories.type', 'fmus.forest_type', 'required_operator_documents.required_operator_document_group_id')
          docs = docs.where(required_operator_documents: { country_id: country_id }) if country_id.present?

          types = (docs.pluck(:type) + [nil]).uniq
          forest_types = (docs.pluck(:forest_type) + [nil]).uniq
          groups = (docs.pluck(:required_operator_document_group_id) + [nil]).uniq

          to_save = []
          to_update = []

          types.each do |type|
            forest_types.each do |forest_type|
              groups.each do |group_id|
                filtered = docs.select do |d|
                  (forest_type.nil? || d.forest_type == forest_type) &&
                    (type.nil? || d.type == type) &&
                    (group_id.nil? || d.required_operator_document_group_id == group_id)
                end.group_by(&:status)

                new_score = OperatorDocumentStatistic.new(
                  document_type: case type
                                 when 'OperatorDocumentFmuHistory'
                                   'fmu'
                                 when 'OperatorDocumentCountryHistory'
                                   'country'
                                 end,
                  fmu_forest_type: forest_type,
                  required_operator_document_group_id: group_id,
                  country_id: country_id,
                  date: day,
                  pending_count: filtered['doc_pending']&.count || 0,
                  invalid_count: filtered['doc_invalid']&.count || 0,
                  valid_count: filtered['doc_valid']&.count || 0,
                  expired_count: filtered['doc_expired']&.count || 0,
                  not_required_count: filtered['doc_not_required']&.count || 0,
                  not_provided_count: filtered['doc_not_provided']&.count || 0,
                )

                # filtered = docs
                # filtered = filtered.where(fmus: { forest_type: forest_type }) if forest_type.present?
                # filtered = filtered.where(required_operator_documents: { required_operator_document_group_id: group_id }) if group_id.present?
                # filtered = filtered.where(type: type) if type.present?

                # statuses = filtered.unscope(:select).group(:status).count

                # new_score = OperatorDocumentStatistic.new(
                #   document_type: case type
                #                  when 'OperatorDocumentFmuHistory'
                #                    'fmu'
                #                  when 'OperatorDocumentCountryHistory'
                #                    'country'
                #                  end,
                #   fmu_forest_type: forest_type,
                #   required_operator_document_group_id: group_id,
                #   country_id: country_id,
                #   date: day,
                #   pending_count: statuses[OperatorDocument.statuses['doc_pending']] || 0,
                #   invalid_count: statuses[OperatorDocument.statuses['doc_invalid']] || 0,
                #   valid_count: statuses[OperatorDocument.statuses['doc_valid']] || 0,
                #   expired_count: statuses[OperatorDocument.statuses['doc_expired']] || 0,
                #   not_required_count: statuses[OperatorDocument.statuses['doc_not_required']] || 0,
                #   not_provided_count: statuses[OperatorDocument.statuses['doc_not_provided']] || 0
                # )

                prev_score = new_score.previous_score
                if prev_score.present? && prev_score == new_score && prev_score.previous_score.present?
                  Rails.logger.info "Prev score the same, update date of prev score"
                  prev_score.date = day
                  prev_score.updated_at = DateTime.current
                  to_update << prev_score
                else
                  Rails.logger.info "Adding score for country: #{country_id} and #{day}"
                  to_save << new_score
                end
              end
            end
          end

          puts "Adding score for country: #{country_id} and #{day}, count: #{to_save.count}"
          OperatorDocumentStatistic.import! to_save
          OperatorDocumentStatistic.import! to_update, on_duplicate_key_update: { columns: %i[date updated_at] }

          # gs.general_status = docs
          #   .map do |d|
          #     {
          #       t: d.type === 'OperatorDocumentCountryHistory' ? 'country' : 'fmu',
          #       g: d.required_operator_document_group_id,
          #       f: d.forest_type,
          #       s: OperatorDocument.statuses[d.status]
          #     }
          #   end
          # prev_score = gs.previous_score
          # next if prev_score.present? && prev_score == gs

          # puts "Adding score for country: #{country_id} and #{day}"
          # gs.save!
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
