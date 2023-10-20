# frozen_string_literal: true

class ExpirationNotifierService
  NOTIFICATION_PERIODS = [-1.day, 1.day, 1.week, 1.month]

  # @param [Date] date The date for which to notify the users
  def initialize(date = Time.zone.today)
    @notification_dates = NOTIFICATION_PERIODS.map { |x| date + x }
  end

  def call
    documents_to_notify
  end

  private

  def documents_to_notify
    @notification_dates.each do |date|
      OperatorDocument.where(expire_date: date).select(:operator_id).group(:operator_id).each do |operator_document|
        documents = OperatorDocument.where(expire_date: date, operator_id: operator_document.operator_id)
        operator = Operator.find(operator_document.operator_id)
        operator.users.filter_active.each do |user|
          OperatorMailer.expiring_documents(operator, user, documents).deliver_now
        end
      end
    end
  end
end
