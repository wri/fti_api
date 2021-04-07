# frozen_string_literal: true

class ExpirationNotifierService
  NOTIFICATION_PERIODS = [1.day, 1.week, 1.month]

  # @param [Date] date The date for which to notify the users
  def initialize(date = Date.today)
    @notification_dates = NOTIFICATION_PERIODS.map { |x| date - x }
  end

  def call
    documents_to_notify
  end

  private

  def documents_to_notify
    @notification_dates.each do |date|
      OperatorDocument.where(expire_date: date).select(:operator_id).group(:operator_id) do |operator|
        documents = OperatorDocument.active.where(expire_date: date, operator_id: operator.id)
        SendExpirationEmailJob.perform_later(operator, documents)
      end
    end
  end
end
