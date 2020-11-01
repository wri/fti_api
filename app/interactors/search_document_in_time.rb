# frozen_string_literal: true

class SearchDocumentInTime
  include Interactor

  def call
    context.fail!(message: 'You must provide an operator-id') if params.dig('filter', 'operator-id').blank?
    context.fail!(message: 'You must provide a date') if params.dig('filter', 'date').blank?
    context.fail!(message: 'Operator must be an integer') unless params['filter']['operator-id'].is_a?(Integer)

    begin
      params['filter']['operator-id'].to_date
    rescue ArgumentError
      context.fail!(message: 'Invalid date format. Use: YYYY-MM-DD')
    end
  end
end