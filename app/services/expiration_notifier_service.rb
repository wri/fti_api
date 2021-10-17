# frozen_string_literal: true

class ExpirationNotifierService
  NOTIFICATION_PERIODS = [1.day, 1.week, 1.month]

  # @param [Date] date The date for which to notify the users
  def initialize(date = Date.today)
    @notification_dates = NOTIFICATION_PERIODS.map { |x| date + x }.push(Date.yesterday)
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
        # We need an email adress to send the email
        # Almost all the operator have email == nil
        # we could use the document.user.email but
        # also a huge number of document.user_id are nil
        SendExpirationEmailJob.perform_now(operator, documents) unless operator.email == nil 
        # SendExpirationEmailJob.perform_later(operator, documents)
      end
    end
  end
end
