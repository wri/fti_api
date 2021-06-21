# frozen_string_literal: true

class RankingOperatorDocument
  class << self
    def refresh_for_country(country)
      new_ranking = ranking(country.id)
      rankable_country_operators = rankable_operators.where(country: country)
      rankable_country_operators.find_each do |operator|
        refresh_operator_rank(operator, new_ranking)
      end

      # cleanup ranking for non rankable operators which has ranking
      Operator
        .where(country: country)
        .where.not(id: rankable_country_operators)
        .where.not(country_doc_rank: nil)
        .find_each do |operator|
          operator.update(country_doc_rank: nil, country_operators: nil)
        end
    end

    def refresh
      new_ranking = ranking
      rankable_operators.find_each do |operator|
        refresh_operator_rank(operator, new_ranking)
      end

      # cleanup ranking for non rankable operators which has ranking
      Operator.where.not(id: rankable_operators).where.not(country_doc_rank: nil).find_each do |operator|
        operator.update(country_doc_rank: nil, country_operators: nil)
      end
    end

    def rankable_operators
      Operator.active.fa_operator
    end

    def refresh_operator_rank(operator, new_ranking)
      new_rank = new_ranking.find { |r| r[:operator_id] == operator.id }
      return if new_rank.nil?

      operator.country_doc_rank = new_rank[:country_doc_rank]
      operator.country_operators = new_rank[:country_operators]

      return unless operator.country_doc_rank_changed? || operator.country_operators_changed?

      operator.save
    end

    def ranking(country_id = nil)
      # Rules: COPIED OVER from old service
      # Operators must have FA_ID
      # Operators that have 0 documents should all be last with the ranking equal to the number of operators
      country_query = country_id.nil? ? "" : " AND c.id = #{country_id}"
      query =
      <<~SQL
        SELECT
          o.id as operator_id,
          o.country_id,
          CASE
          WHEN "all" = 0 THEN
            COUNT(*) OVER (PARTITION BY o.country_id)
          ELSE
            RANK() OVER (PARTITION BY o.country_id ORDER BY "all" DESC)
          END as country_doc_rank,
          COUNT(*) OVER (PARTITION BY o.country_id) as country_operators
        FROM score_operator_documents sod
          INNER JOIN operators o on o.id = sod.operator_id
            AND o.fa_id <> ''
            AND o.is_active = true
            AND sod.current = true
          INNER JOIN countries c on c.id = o.country_id AND c.is_active = true #{country_query}
      SQL

      ActiveRecord::Base.connection.execute(query).to_a.map(&:with_indifferent_access)
    end
  end
end
