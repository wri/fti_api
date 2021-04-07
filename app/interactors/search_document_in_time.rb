# frozen_string_literal: true

class SearchDocumentInTime
  include Interactor

  def call
    filter = context.filter
    context.fail!(message: 'Please add the date and operator-id filters') if filter.blank?
    context.fail!(message: 'You must provide an operator-id') if filter['operator-id'].blank?
    context.fail!(message: 'You must provide a date') if filter['date'].blank?
    context.fail!(message: 'Operator must be an integer') unless filter['operator-id'].to_i.to_s == filter['operator-id']
    
    begin
      filter['date'].to_date
    rescue ArgumentError
      context.fail!(message: 'Invalid date format. Use: YYYY-MM-DD')
    end
  end
end
