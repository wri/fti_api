class OperatorMailer < ApplicationMailer
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper

  helper :date

  # An email that contains the a quarterly report of an operator
  # It lists:
  # 1. Current transparency score
  # 2. Change of score in the last quarter
  # 3. List of documents expiring in the next quarter
  # It's sent every quarter to all users of an operator
  def quarterly_newsletter(operator, user)
    @user = user
    current_score = operator.score_operator_document
    last_score = operator.score_operator_documents.at_date(Time.zone.today - 3.months).order(:date).last
    @expiring_docs = operator.operator_documents.to_expire(Time.zone.today + 3.months)
    @operator = operator

    @score = begin
      float_to_percentage(current_score.all)
    rescue
      0
    end

    if last_score.present?
      @old_score = begin
        float_to_percentage(last_score.all)
      rescue
        0
      end
      @old_score_date = last_score.date
      @score_variation = float_to_percentage(current_score.all - last_score.all)
    end

    mail to: user.email, subject: I18n.t("operator_mailer.quarterly_newsletter.subject", company: operator.name)
  end

  private

  def float_to_percentage(number)
    number_to_percentage(number * 100, precision: 2, strip_insignificant_zeros: true)
  end
end
