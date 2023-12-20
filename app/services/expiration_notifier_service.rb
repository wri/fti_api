# frozen_string_literal: true

class ExpirationNotifierService
  NOTIFICATION_PERIODS = [-1.day, 1.day, 1.week, 1.month]

  # @param [Date] date The date for which to notify the users
  def initialize(date = Time.zone.today)
    @notification_dates = NOTIFICATION_PERIODS.map { |x| date + x }
  end

  def call
    @notification_dates.each do |date|
      OperatorDocument.expirable.where(expire_date: date).pluck(:operator_id).uniq.each do |operator_id|
        documents = OperatorDocument.expirable.where(expire_date: date, operator_id: operator_id)
        operator = Operator.find(operator_id)
        operator.all_users.filter_actives.each do |user|
          I18n.with_locale(user.locale.presence || I18n.default_locale) do
            OperatorMailer.expiring_documents(operator, user, documents).deliver_now
          end
        end
      end
    end
  end
end
