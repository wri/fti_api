class RankingOperatorDocumentService
  def initialize
  end

  # Calculates the ranking based on the documents
  def call
    Country.active.find_each { |country| calculate_country(country)}
  end

  private

  # Calculates the ranking for the country, based on the score_operator_document
  # @param [Country] country The country for which to calculate the ranking
  def calculate_country(country)
    RankingOperatorDocument.transaction do
      # Makes all the previous ROD inactive
      RankingOperatorDocument.where(country: country).update_all(current: false)
      # Update the operator "updated_at" to invalidate the cache
      Operator.joins(:ranking_operator_documents)
        .where(ranking_operator_documents: {country: country}).update_all(updated_at: Time.now)
      # Rules:
      # Operators must have FA_ID
      # Operators that have 0 documents should all be last with the ranking equal to the number of operators
      query = <<~SQL
        INSERT INTO ranking_operator_documents(operator_id, position, country_id, current, date, created_at, updated_at)
        SELECT operators.id, RANK() OVER (ORDER BY "all" DESC), #{country.id}, true, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP 
        FROM score_operator_documents
        INNER JOIN operators on operators.id = score_operator_documents.operator_id
        WHERE country_id = #{country.id}
        AND operators.fa_id <> 'NULL'
        AND score_operator_documents.current = true
        AND "all" <> 0
      SQL
      ActiveRecord::Base.connection.execute query
      # Updates the ranking operator documents for the operators that have 0 documents
      operator_count = Operator.where(country: country).fa_operator.count
      query = <<~SQL
        INSERT INTO ranking_operator_documents(operator_id, position, country_id, current, date, created_at, updated_at)
        SELECT operators.id, #{operator_count}, #{country.id}, true, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP 
        FROM score_operator_documents
        INNER JOIN operators on operators.id = score_operator_documents.operator_id
        WHERE country_id = #{country.id}
        AND operators.fa_id <> 'NULL'
        AND score_operator_documents.current = true
        AND "all" = 0
      SQL
      ActiveRecord::Base.connection.execute query
    end
  end
end