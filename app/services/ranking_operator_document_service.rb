class RankingOperatorDocumentService
  def initialize
  end

  # Calculates the ranking based on the documents
  def call
    Country.active.find_each { |country| calculate_country(country)}
  end

  private

  def calculate_country(country)
    RankingOperatorDocument.transaction do
      RankingOperatorDocument.where(country: country).update_all(current: false)
      query = <<~SQL
        INSERT INTO ranking_operator_documents(operator_id, position, country_id, current, date, created_at, updated_at)
        SELECT operators.id, RANK() OVER (ORDER BY 'all'), #{country.id}, true, CURRENT_DATE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP 
        FROM score_operator_documents
        INNER JOIN operators on operators.id = score_operator_documents.operator_id
        WHERE country_id = #{country.id}
      SQL
      ActiveRecord::Base.execute query
    end
  end
end