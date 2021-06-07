class RankingOperatorDocument
  include ActiveModel::Model

  attr_accessor :operator_id, :country_id, :position, :total

  class << self
    def for_operator(operator)
      return unless operator.present?

      calculated_ranking
        .select { |ranking| ranking['operator_id'] == operator.id }
        .map { |ranking| RankingOperatorDocument.new(ranking) }
        .first
    end

    def reload
      @calculated_ranking = nil
    end

    private

    def calculated_ranking
      # Rules: COPIED OVER from old service
      # Operators must have FA_ID
      # Operators that have 0 documents should all be last with the ranking equal to the number of operators
      query =
      <<~SQL
        SELECT
          operators.id as operator_id,
          country_id,
          CASE
          WHEN "all" = 0 THEN
            COUNT(*) OVER (PARTITION BY country_id)
          ELSE
            RANK() OVER (PARTITION BY country_id ORDER BY "all" DESC)
          END as position,
          COUNT(*) OVER (PARTITION BY country_id) as total
        FROM score_operator_documents
          INNER JOIN operators on operators.id = score_operator_documents.operator_id
            AND operators.fa_id <> 'NULL'
            AND operators.is_active = true
            AND score_operator_documents.current = true
      SQL

      @calculated_ranking ||= ActiveRecord::Base.connection.execute(query).to_a
    end
  end
end
