# frozen_string_literal: true

class SearchDocumentInTime
  include Interactor

  def call
    filter = context.filter
    context.fail!(message: 'Please add the date and operator-id filters') if filter.blank?
    context.fail!(message: 'You must provide an operator-id') if filter['operator-id'].blank?
    context.fail!(message: 'You must provide a date') if filter['date'].blank?

    begin
      Integer(filter['operator-id'])
    rescue ArgumentError
      context.fail!(message: 'Operator must be an integer')
    end
    begin
      filter['date'].to_date
    rescue ArgumentError
      context.fail!(message: 'Invalid date format. Use: YYYY-MM-DD')
    end
  end
end
