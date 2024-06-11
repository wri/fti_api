# frozen_string_literal: true

class ExpirationNotifierService
  NOTIFICATION_PERIODS = [-1.day, 1.day, 1.week, 1.month]

  def initialize
    @notification_dates = NOTIFICATION_PERIODS.map { |x| Time.zone.today + x }
  end

  def call
    @notification_dates.each do |date|
      send_notifications_for_operator_documents(date)
      send_notifications_for_gov_documents(date)
    end
  end

  private

  def send_notifications_for_operator_documents(date)
    operators.each do |operator|
      documents = date.past? ? OperatorDocument.doc_expired : OperatorDocument.expirable
      documents = documents.where(expire_date: date, operator_id: operator.id)
      next if documents.none?

      operator.all_users.filter_actives.each do |user|
        I18n.with_locale(user.locale.presence || I18n.default_locale) do
          if date.past?
            OperatorDocumentMailer.expired_documents(operator, user, documents).deliver_now
          else
            OperatorDocumentMailer.expiring_documents(operator, user, documents).deliver_now
          end
        end
      end
    end
  end

  def send_notifications_for_gov_documents(date)
    countries.each do |country|
      documents = date.past? ? GovDocument.doc_expired : GovDocument.expirable
      documents = documents.where(expire_date: date, country_id: country.id)
      next if documents.none?

      country.users.filter_governments.filter_actives.each do |user|
        I18n.with_locale(user.locale.presence || I18n.default_locale) do
          if date.past?
            GovDocumentMailer.expired_documents(country, user, documents).deliver_now
          else
            GovDocumentMailer.expiring_documents(country, user, documents).deliver_now
          end
        end
      end
    end
  end

  def countries
    Country.where(id: GovDocument.expirable.or(GovDocument.doc_expired).where(expire_date: @notification_dates).pluck(:country_id).uniq)
  end

  def operators
    Operator.where(
      id: OperatorDocument.expirable.or(OperatorDocument.doc_expired).where(expire_date: @notification_dates).pluck(:operator_id).uniq
    )
  end
end
